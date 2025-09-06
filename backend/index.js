import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";
import crypto from "crypto";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

// 🔹 Credenciales Mercado Pago desde variables de entorno
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

// 🔹 Ruta GET para pruebas de Mercado Pago
app.get("/webhook/mercadopago", (req, res) => {
  console.log("🔍 Prueba de Mercado Pago recibida:", req.query);
  res.status(200).send("OK");
});

// 🔹 Ruta POST para recibir notificaciones de pago reales (IPN)
app.post("/webhook/mercadopago", express.raw({ type: "*/*" }), (req, res) => {
  try {
    const signature = req.headers["x-signature"];
    const requestId = req.headers["x-request-id"];
    const secret = process.env.MP_WEBHOOK_SECRET;

    console.log("🔔 Webhook recibido. Headers:", req.headers);
    console.log("🔔 Body:", req.body.toString());

    // Responder rápido al webhook
    res.sendStatus(200);

    if (!signature || !requestId || !secret) {
      console.warn("⚠️ No se pudo validar firma: faltan datos");
      return;
    }

    // Parsear el body y obtener dataId desde el body
    const event = JSON.parse(req.body.toString());
    const dataId = event.data?.id;

    if (!dataId) {
      console.warn("⚠️ data.id no encontrado en el body");
      return;
    }

    // Extraer ts y v1 del header
    const ts = signature.split(",").find((s) => s.includes("ts"))?.split("=")[1];
    const v1 = signature.split(",").find((s) => s.includes("v1"))?.split("=")[1];

    if (!ts || !v1) {
      console.warn("⚠️ Falta ts o v1");
      return;
    }

    // Validar HMAC
    const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
    const computedHmac = crypto.createHmac("sha256", secret).update(manifest).digest("hex");

    if (computedHmac !== v1) {
      console.warn("⚠️ Firma inválida");
      return;
    }

    console.log("✅ Firma válida para el pago:", dataId);

    if (event.type === "payment") {
      console.log(`💰 Pago confirmado: ${dataId}`);
      // TODO: Guardar en tu base de datos si deseas
    }
  } catch (error) {
    console.error("❌ Error procesando webhook:", error);
  }
});

// 🔹 Ahora ponemos express.json() para el resto de endpoints
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
