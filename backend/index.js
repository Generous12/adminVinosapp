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

/* -------------------------------------------------------------------
   WEBHOOK (nuevo sistema con firma HMAC)
------------------------------------------------------------------- */
// 🔹 Ruta GET para que Mercado Pago pueda probar la URL
app.get("/webhook/mercadopago", (req, res) => {
  console.log("🔍 Prueba de Mercado Pago recibida:", req.query);
  res.status(200).send("OK");
});

// 🔹 Ruta real para recibir notificaciones de pago (webhook nuevo)
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
      console.log(`✅ Pago confirmado (webhook): ${event.data.id}`);
      // TODO: Guardar en tu base de datos
    }
  } catch (error) {
    console.error("❌ Error procesando webhook:", error);
  }
});

/* -------------------------------------------------------------------
   IPN (sistema clásico, id + topic en querystring)
------------------------------------------------------------------- */
app.post("/ipn/mercadopago", express.urlencoded({ extended: false }), async (req, res) => {
  try {
    const { id, topic } = req.query;
    console.log("📩 IPN recibido:", req.query);

    if (!id || !topic) {
      console.warn("⚠️ IPN sin id o topic");
      return res.sendStatus(400);
    }

    if (topic === "payment") {
      const payment = await paymentClient.get({ id });
      console.log("✅ Pago vía IPN:", payment);
      // TODO: Guardar en base de datos
    }

    res.sendStatus(200);
  } catch (err) {
    console.error("❌ Error procesando IPN:", err);
    res.sendStatus(500);
  }
});

/* -------------------------------------------------------------------
   Resto de endpoints
------------------------------------------------------------------- */
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
      // 🔹 Apunta al webhook nuevo, no al IPN
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

/* -------------------------------------------------------------------
   Start server
------------------------------------------------------------------- */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor escuchando en puerto ${PORT}`));
