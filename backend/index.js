import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";
import crypto from "crypto";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

// 🔹 Credenciales desde variables de entorno
const MP_CLIENT_ID = process.env.MP_CLIENT_ID;
const MP_CLIENT_SECRET = process.env.MP_CLIENT_SECRET;
const ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN?.trim();
if (!ACCESS_TOKEN) {
  console.error("❌ ERROR: La variable MP_ACCESS_TOKEN no está definida o es vacía.");
  process.exit(1);
}
console.log("✅ MP_ACCESS_TOKEN cargado correctamente");

const client = new MercadoPagoConfig({ accessToken: ACCESS_TOKEN });
const preferenceClient = new Preference(client);
const paymentClient = new Payment(client);

const app = express();
app.use(cors());

// ======================
// 🔹 RUTA IPN CLÁSICA
// ======================
app.post("/ipn/mercadopago", express.urlencoded({ extended: false }), async (req, res) => {
  try {
    const { id, topic } = req.query;
    console.log("📩 IPN recibido:", req.query);

    res.sendStatus(200); // siempre responde rápido a MP

    if (!id || !topic) {
      console.warn("⚠️ IPN sin id o topic");
      return;
    }

    if (topic === "payment") {
      // 🔹 Consultar pago
      try {
        const pago = await paymentClient.get({ id });
        console.log("✅ Pago recibido:", pago.id, pago.status);
        // TODO: Guardar en BD
      } catch (e) {
        console.warn("⚠️ No se encontró el pago con id:", id);
      }
    }

    if (topic === "merchant_order") {
      // 🔹 Consultar merchant_order
      const response = await fetch(`https://api.mercadopago.com/merchant_orders/${id}`, {
        headers: { Authorization: `Bearer ${ACCESS_TOKEN}` },
      });
      const order = await response.json();

      if (order.error) {
        console.warn("⚠️ Merchant Order no encontrada:", order);
        return;
      }

      console.log("✅ Merchant Order recibida:", order.id, order.status);

      if (order.payments && order.payments.length > 0) {
        console.log("💰 Pagos asociados:");
        order.payments.forEach((p) => {
          console.log(`   - PaymentID: ${p.id}, Status: ${p.status}, Amount: ${p.total_paid_amount}`);
        });
      }
      // TODO: Guardar en BD
    }
  } catch (err) {
    console.error("❌ Error procesando IPN:", err);
  }
});



// ======================
// 🔹 RUTA WEBHOOK (firma)
// ======================

// GET para prueba de conexión
app.get("/webhook/mercadopago", (req, res) => {
  console.log("🔍 Prueba de Mercado Pago recibida:", req.query);
  res.status(200).send("OK");
});

// POST real con validación de firma
app.post("/webhook/mercadopago", express.raw({ type: "*/*" }), async (req, res) => {
  try {
    const signature = req.headers["x-signature"];
    const requestId = req.headers["x-request-id"];
    const url = new URL(req.protocol + "://" + req.get("host") + req.originalUrl);
    const dataId = url.searchParams.get("data.id");
    const secret = process.env.MP_WEBHOOK_SECRET;

    console.log("🔔 Webhook recibido. Headers:", req.headers);
    console.log("🔔 Query:", url.searchParams.toString());
    console.log("🔔 Body:", req.body.toString());

    res.sendStatus(200);

    if (!signature || !requestId || !dataId || !secret) {
      console.warn("⚠️ No se pudo validar firma (faltan datos)");
      return;
    }

    const ts = signature.split(",").find((s) => s.includes("ts"))?.split("=")[1];
    const v1 = signature.split(",").find((s) => s.includes("v1"))?.split("=")[1];
    if (!ts || !v1) {
      console.warn("⚠️ Falta ts o v1 en firma");
      return;
    }

    const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
    const computedHmac = crypto
      .createHmac("sha256", secret)
      .update(manifest)
      .digest("hex");

    if (computedHmac !== v1) {
      console.warn("⚠️ Firma inválida");
      return;
    }

    // Firma válida
    const event = JSON.parse(req.body.toString());
    console.log("✅ Webhook validado:", event);

    if (event.type === "payment") {
      console.log(`💰 Pago confirmado (Webhook): ${event.data.id}`);
      // TODO: Guardar en BD
    }
  } catch (error) {
    console.error("❌ Error procesando webhook:", error);
  }
});

// ======================
// 🔹 RESTO ENDPOINTS
// ======================

// Usar JSON normal para el resto
app.use(express.json());

// Crear preferencia
app.post("/crear-preferencia", async (req, res) => {
  try {
    const { items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0)
      return res.status(400).json({ error: "Items inválidos o vacíos" });

    const preferenceData = {
      items,
      back_urls: {
        success: "https://tusitio.com/success",
        failure: "https://tusitio.com/failure",
        pending: "https://tusitio.com/pending",
      },
      auto_return: "approved",
      payment_methods: { installments: 1 },
      // 🔹 Puedes registrar ambos si quieres:
      notification_url: "https://adminvinosapp-production.up.railway.app/ipn/mercadopago",
    };

    console.log("📦 Items enviados a MP:", items);

    const response = await preferenceClient.create({ body: preferenceData });

    console.log("✅ Preferencia creada:", response.init_point);

    res.json({
      init_point: response.init_point,
      preference_id: response.id,
    });
  } catch (error) {
    console.error("Error creando preferencia:", error.response?.data || error);
    res.status(500).json({
      error: "Error creando preferencia",
      detalle: error.response?.data?.message || error.message || error,
    });
  }
});

// Verificar pago o preferencia
app.get("/verificar/:id", async (req, res) => {
  const { id } = req.params;
  if (!id) return res.status(400).json({ error: "ID requerido" });

  try {
    try {
      const payment = await paymentClient.get({ id });
      return res.json({
        tipo: "payment",
        id: payment.id,
        status: payment.status,
        status_detail: payment.status_detail,
      });
    } catch {
      const preference = await preferenceClient.get({ id });
      return res.json({
        tipo: "preference",
        id: preference.id,
        status: preference.status,
        init_point: preference.init_point,
        items: preference.items,
      });
    }
  } catch (err) {
    console.error("Error verificando ID:", err);
    res.status(500).json({
      error: "No se pudo verificar el ID",
      detalle: err.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor escuchando en puerto ${PORT}`));
