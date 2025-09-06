import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";
import crypto from "crypto";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

// 🔹 Credenciales desde variables de entorno
const ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN?.trim();
const WEBHOOK_SECRET = process.env.MP_WEBHOOK_SECRET?.trim();

if (!ACCESS_TOKEN) {
  console.error("❌ MP_ACCESS_TOKEN no está definido");
  process.exit(1);
}
if (!WEBHOOK_SECRET) {
  console.error("❌ MP_WEBHOOK_SECRET no está definido");
  process.exit(1);
}

const client = new MercadoPagoConfig({ accessToken: ACCESS_TOKEN });
const preferenceClient = new Preference(client);
const paymentClient = new Payment(client);

const app = express();
app.use(cors());
app.use(express.json());

// 🔹 URLs públicas de Railway
const WEBHOOK_URL = "https://adminvinosapp-production.up.railway.app/webhook/mercadopago";
const IPN_URL = "https://adminvinosapp-production.up.railway.app/ipn/mercadopago";

// 🔹 Ruta GET para pruebas de Mercado Pago
app.get("/webhook/mercadopago", (req, res) => {
  console.log("🔍 Prueba de Mercado Pago recibida:", req.query);
  res.status(200).send("OK");
});

// 🔹 Webhook moderno (v1)
app.post("/webhook/mercadopago", express.raw({ type: "*/*" }), (req, res) => {
  try {
    const signature = req.headers["x-signature"];
    const requestId = req.headers["x-request-id"];
    const url = new URL(req.protocol + "://" + req.get("host") + req.originalUrl);
    const dataId = url.searchParams.get("data.id");

    console.log("🔔 Webhook recibido. Headers:", req.headers);
    console.log("🔔 Query:", url.searchParams.toString());
    console.log("🔔 Body:", req.body.toString());

    res.sendStatus(200);

    if (signature && requestId && dataId) {
      const ts = signature.split(",").find(s => s.includes("ts"))?.split("=")[1];
      const v1 = signature.split(",").find(s => s.includes("v1"))?.split("=")[1];

      if (ts && v1) {
        const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
        const computedHmac = crypto
          .createHmac("sha256", WEBHOOK_SECRET)
          .update(manifest)
          .digest("hex");

        if (computedHmac !== v1) {
          console.warn("⚠️ Firma inválida");
          return;
        }
      }
    }

    // Solo parsea JSON si el body no está vacío
    if (req.body && req.body.length) {
      const event = JSON.parse(req.body.toString());
      if (event.type === "payment") {
        console.log(`✅ Pago confirmado (Webhook moderno): ${event.data.id}`);
        // TODO: Guardar en base de datos
      }
    } else {
      console.log("⚠️ Webhook recibido con body vacío (IPN o prueba)");
    }
  } catch (error) {
    console.error("❌ Error procesando Webhook:", error);
  }
});

// 🔹 Soporte para IPN/legacy
app.post("/ipn/mercadopago", async (req, res) => {
  try {
    const { topic, id } = req.query;
    res.sendStatus(200); // siempre responder primero

    if (topic === "payment" && id) {
      // 1️⃣ Obtener la notificación desde Mercado Pago
      const notification = await client.get(`/v1/payments/${id}`).catch(err => null);

      if (!notification) {
        console.warn(`⚠️ Payment not found para notification id: ${id}`);
        return;
      }

      console.log(`✅ Pago confirmado (IPN): ${notification.body.id}`);
      // TODO: Guardar en base de datos
    }
  } catch (err) {
    console.error("❌ Error procesando IPN:", err);
  }
});

// 🔹 Crear preferencia
app.post("/crear-preferencia", async (req, res) => {
  try {
    const { items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: "Items inválidos o vacíos" });
    }

    // Validar items
    for (const item of items) {
      if (
        !item.title ||
        typeof item.quantity !== "number" ||
        typeof item.unit_price !== "number" ||
        !item.currency_id
      ) {
        return res.status(400).json({ error: "Item con formato incorrecto" });
      }
    }

    const preferenceData = {
      items,
      back_urls: {
        success: "https://tusitio.com/success",
        failure: "https://tusitio.com/failure",
        pending: "https://tusitio.com/pending",
      },
      auto_return: "approved",
      payment_methods: { installments: 1 },
      notification_url: WEBHOOK_URL,
    };

    console.log("📦 Items enviados a Mercado Pago:", items);

    const response = await preferenceClient.create({ body: preferenceData });
    console.log("✅ Preferencia creada:", response.init_point);

    res.json({ init_point: response.init_point, preference_id: response.id });
  } catch (error) {
    console.error("❌ Error creando preferencia:", error.response?.data || error);
    res.status(500).json({
      error: "Error creando preferencia",
      detalle: error.response?.data?.message || error.message || error,
    });
  }
});

// 🔹 Verificar pago
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
    console.error("❌ Error verificando ID:", err);
    res.status(500).json({
      error: "No se pudo verificar el ID",
      detalle: err.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor escuchando en puerto ${PORT}`));
