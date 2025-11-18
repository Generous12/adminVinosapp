import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";
import crypto from "crypto";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

const MP_CLIENT_ID = process.env.MP_CLIENT_ID;
const MP_CLIENT_SECRET = process.env.MP_CLIENT_SECRET;
const ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN?.trim();
if (!ACCESS_TOKEN) {
  console.error("ERROR: MP_ACCESS_TOKEN no definido.");
  process.exit(1);
}
console.log("MP_ACCESS_TOKEN cargado");

const client = new MercadoPagoConfig({ accessToken: ACCESS_TOKEN });
const preferenceClient = new Preference(client);
const paymentClient = new Payment(client);

const app = express();
app.use(cors());

app.post("/ipn/mercadopago", express.urlencoded({ extended: false }), async (req, res) => {
  try {
    const { id, topic } = req.query;
    console.log("IPN recibido:", req.query);
    res.sendStatus(200);

    if (!id || !topic) return;

    if (topic === "payment") {
      try {
        const pago = await paymentClient.get({ id });
        console.log("Pago recibido:", pago.id, pago.status);
      } catch (e) {
        if (id === "123456") {
          console.log("Notificación de prueba 123456.");
        } else {
          console.warn("Pago no encontrado:", id);
        }
      }
    }

    if (topic === "merchant_order") {
      const response = await fetch(`https://api.mercadopago.com/merchant_orders/${id}`, {
        headers: { Authorization: `Bearer ${ACCESS_TOKEN}` },
      });
      const order = await response.json();

      if (order.error) return;

      console.log("Merchant Order:", order.id, order.status);

      if (order.payments?.length) {
        order.payments.forEach((p) => {
          console.log(`PaymentID: ${p.id}, Status: ${p.status}, Amount: ${p.total_paid_amount}`);
        });
      }
    }
  } catch (err) {
    console.error("Error IPN:", err);
  }
});

app.get("/webhook/mercadopago", (req, res) => {
  console.log("Webhook GET:", req.query);
  res.status(200).send("OK");
});

app.post("/webhook/mercadopago", express.raw({ type: "*/*" }), async (req, res) => {
  try {
    const signature = req.headers["x-signature"];
    const requestId = req.headers["x-request-id"];
    const url = new URL(req.protocol + "://" + req.get("host") + req.originalUrl);
    const dataId = url.searchParams.get("data.id");
    const secret = process.env.MP_WEBHOOK_SECRET;

    console.log("Webhook recibido:", req.headers);
    console.log("Query:", url.searchParams.toString());
    console.log("Body:", req.body.toString());

    res.sendStatus(200);

    if (!signature || !requestId || !dataId || !secret) return;

    const ts = signature.split(",").find((s) => s.includes("ts"))?.split("=")[1];
    const v1 = signature.split(",").find((s) => s.includes("v1"))?.split("=")[1];
    if (!ts || !v1) return;

    const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
    const computedHmac = crypto
      .createHmac("sha256", secret)
      .update(manifest)
      .digest("hex");

    if (computedHmac !== v1) return;

    const event = JSON.parse(req.body.toString());
    console.log("Webhook validado:", event);

    if (event.type === "payment") {
      console.log(`Pago Webhook: ${event.data.id}`);
    }
  } catch (error) {
    console.error("Error Webhook:", error);
  }
});

app.use(express.json());

app.post("/crear-preferencia", async (req, res) => {
  try {
    const { items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0)
      return res.status(400).json({ error: "Items inválidos" });

    const preferenceData = {
      items,
      back_urls: {
        success: "https://tusitio.com/success",
        failure: "https://tusitio.com/failure",
        pending: "https://tusitio.com/pending",
      },
      auto_return: "approved",
      payment_methods: { installments: 1 },
      notification_url: "https://adminvinosapp-production.up.railway.app/ipn/mercadopago",
    };

    console.log("Items enviados:", items);

    const response = await preferenceClient.create({ body: preferenceData });

    console.log("Preferencia creada:", response.init_point);

    res.json({
      init_point: response.init_point,
      preference_id: response.id,
    });
  } catch (error) {
    console.error("Error preferencia:", error.response?.data || error);
    res.status(500).json({
      error: "Error creando preferencia",
      detalle: error.response?.data?.message || error.message,
    });
  }
});

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
    console.error("Error verificar:", err);
    res.status(500).json({
      error: "No se pudo verificar",
      detalle: err.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor escuchando en puerto ${PORT}`));
