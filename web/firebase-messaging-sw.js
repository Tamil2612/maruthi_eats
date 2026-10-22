// Firebase Messaging Service Worker for Maruthi Eats PWA Push Notifications
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAlnBDuqrG9DiwdarS2H2iZXhr2IzAq1bM',
  appId: '1:119948554671:web:fc13c7a8836ab824b23f5a',
  messagingSenderId: '119948554671',
  projectId: 'maruthi-eats',
  authDomain: 'maruthi-eats.firebaseapp.com',
  storageBucket: 'maruthi-eats.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background push notification: ', payload);

  // FCM automatically displays messages that contain a `notification`
  // payload. Showing one here as well creates duplicate alerts, especially
  // in an iOS Home Screen PWA. Data-only messages still need manual display.
  if (payload.notification) {
    return;
  }

  const notificationTitle = payload.notification?.title || payload.data?.title || 'Maruthi Eats';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'New update received',
    icon: '/icons/Icon-192.png',
    badge: '/favicon.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const orderId = event.notification.data?.order_id;
  let urlToOpen = self.location.origin;
  if (orderId) {
    urlToOpen = self.location.origin + '/?order_id=' + orderId;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (let i = 0; i < windowClients.length; i++) {
        const client = windowClients[i];
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          // Navigate the already-open PWA to the order from the push. Merely
          // focusing it would leave the customer on the current screen.
          return client.navigate(urlToOpen).then(() => client.focus());
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
