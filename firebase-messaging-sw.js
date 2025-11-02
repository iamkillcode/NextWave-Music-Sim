// Firebase Cloud Messaging Service Worker
// This file is required for Firebase Cloud Messaging to work in web browsers

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBQUUu9pOJq0BfH6qVOxBhDPbkm-gVGPGY",
  authDomain: "nextwave-music-sim.firebaseapp.com",
  projectId: "nextwave-music-sim",
  storageBucket: "nextwave-music-sim.firebasestorage.app",
  messagingSenderId: "554743988495",
  appId: "1:554743988495:web:aff64f44eddf41eb04bcb3",
  measurementId: "G-VJD01DWE1M"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification?.title || 'NextWave Music Sim';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // Open the app when notification is clicked
  event.waitUntil(
    clients.openWindow('/')
  );
});
