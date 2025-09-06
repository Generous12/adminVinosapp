import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";
import crypto from "crypto";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

// 🔹 Credenciales Mercado Pago (producción) desde variables de entorno
const MP_CLIENT_ID = process.env.MP_CLIENT_ID;
const MP_CLIENT_SECRET = process.env.MP_CLIENT_SECRET;
const MP_REDIRECT_URI =
  process.env.MP_REDIRECT_URI ||
  "https://adminvinosapp-production.up.railway.app/webhook";

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
  
// 🔹 Ruta GET para que Mercado Pago pueda probar la URL
app.get("/webhook/mercadopago", (req, res) => {
  console.log("🔍 Prueba de Mercado Pago recibida:", req.query);
  res.status(200).send("OK");
});

// 🔹 Ruta real para recibir notificaciones de pago
app.post("/webhook/mercadopago", express.raw({ type: "*/*" }), (req, res) => {
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
      console.warn("⚠️ No se pudo validar firma");
      return;
    }

    const ts = signature.split(",").find((s) => s.includes("ts"))?.split("=")[1];
    const v1 = signature.split(",").find((s) => s.includes("v1"))?.split("=")[1];
    if (!ts || !v1) {
      console.warn("⚠️ Falta ts o v1");
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

    const event = JSON.parse(req.body.toString());
    if (event.type === "payment") {
      console.log(`✅ Pago confirmado: ${event.data.id}`);
      // TODO: Guardar en tu base de datos
    }
  } catch (error) {
    console.error("❌ Error procesando webhook:", error);
  }
});

// 🔹 Endpoint IPN de Mercado Pago
app.post("/ipn/mercadopago", express.json(), express.urlencoded({ extended: true }), async (req, res) => {
  try {
    // Recibir datos de body o query para pruebas
    const body = Object.keys(req.body).length ? req.body : req.query;
    console.log("📥 IPN recibido:", body);

    const topic = body.topic;
    const id = body.id;
    if (!topic || !id) return res.status(400).send("Faltan parámetros");

    if (topic === "payment") {
      // Obtener información del pago
      const payment = await paymentClient.get({ id });
      console.log("✅ Pago IPN:", {
        id: payment.id,
        status: payment.status,
        status_detail: payment.status_detail,
        amount: payment.transaction_amount,
      });
      // TODO: Guardar en base de datos
    }

    if (topic === "merchant_order") {
      // Obtener información de la orden
      const order = await mercadopagoPkg.merchant_orders.get(id);
      console.log("✅ Orden IPN:", order);
      // TODO: Guardar en base de datos
    }

    res.status(200).send("IPN recibido");
  } catch (error) {
    console.error("❌ Error procesando IPN:", error);
    res.status(500).send("Error procesando IPN");
  }
});


// 🔹 AHORA ponemos express.json() para el resto de endpoints
app.use(express.json());

// 🔹 Crear preferencia
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
      payment_methods: {
          installments: 1,
      },
       notification_url: "https://adminvinosapp-production.up.railway.app/webhook/mercadopago",
    };

    console.log("📦 Items enviados a Mercado Pago:", items);

    const response = await preferenceClient.create({ body: preferenceData });

    console.log("✅ Preferencia creada:", response.init_point);

    res.json({
      init_point: response.init_point,
      preference_id: response.id,
    });
  } catch (error) {
    console.error("Error creando la preferencia:", error.response?.data || error);
    res.status(500).json({
      error: "Error creando la preferencia",
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
    console.error("Error verificando ID:", err);
    res.status(500).json({
      error: "No se pudo verificar el ID",
      detalle: err.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor escuchando en puerto ${PORT}`));