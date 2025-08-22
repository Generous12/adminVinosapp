// index.js — Backend producción SOLO para vincular Mercado Pago (OAuth)

import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import admin from "firebase-admin";

// 🔹 Inicializar Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

const app = express();
app.use(cors());
app.use(express.json());

// 🔹 Credenciales Mercado Pago
const MP_CLIENT_ID = process.env.MP_CLIENT_ID;
const MP_CLIENT_SECRET = process.env.MP_CLIENT_SECRET;
const MP_REDIRECT_URI = process.env.MP_REDIRECT_URI || "https://adminvinosapp-production.up.railway.app/oauth/callback";

// 🔹 Ruta para generar el link de login de Mercado Pago
app.post("/mp/login", (req, res) => {
  const { uid } = req.body; // <-- UID DEL USUARIO LOGUEADO
  if (!uid) return res.status(400).json({ error: "UID requerido" });

  const redirectUrl = `https://auth.mercadopago.com/authorization?client_id=${MP_CLIENT_ID}&response_type=code&platform_id=mp&redirect_uri=${encodeURIComponent(
    MP_REDIRECT_URI
  )}&state=${uid}`; // <-- Pasamos UID en state

  res.json({ url: redirectUrl });
});

// 🔹 Callback Mercado Pago
app.get("/oauth/callback", async (req, res) => {
  try {
    const { code, state } = req.query; // state = UID
    if (!code || !state) return res.status(400).send("Faltan parámetros");

    // Intercambiar el code por tokens
    const tokenResponse = await fetch("https://api.mercadopago.com/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: MP_CLIENT_ID,
        client_secret: MP_CLIENT_SECRET,
        grant_type: "authorization_code",
        code,
        redirect_uri: MP_REDIRECT_URI,
      }),
    });

    const tokenData = await tokenResponse.json();
    if (tokenData.error) {
      console.error("❌ Error en token exchange:", tokenData);
      return res.status(400).json({ error: tokenData });
    }

    const { access_token, refresh_token, user_id, expires_in, token_type, scope } = tokenData;

    // 🔹 Guardar tokens en Firestore, documento con el UID
    await db.collection("empresaVinos").doc(state).set({
      mp_user_id: user_id,
      access_token,
      refresh_token,
      expires_in,
      token_type,
      scope,
      vinculadoEn: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Tokens guardados para UID ${state}`);

   res.redirect("https://adminvinosapp-production.up.railway.app/admin?status=success");
  } catch (err) {
    console.error("❌ Error en OAuth callback:", err);
    res.status(500).send("Error en la autenticación con Mercado Pago");
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor OAuth escuchando en puerto ${PORT}`));
