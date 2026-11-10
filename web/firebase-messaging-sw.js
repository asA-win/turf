importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyBPrp4SezO1VuG6kujDdpNd_LQcAwxW3Yc",
  appId: "1:600790618967:web:2ae7c810ff1f202f60e412",
  messagingSenderId: "600790618967",
  projectId: "turf-d190a",
  authDomain: "turf-d190a.firebaseapp.com",
  storageBucket: "turf-d190a.firebasestorage.app",
  measurementId: "G-Q34QB0KCXF",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
