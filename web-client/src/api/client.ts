import axios from 'axios';

// Auto-detect host from location
const host = window.location.hostname;
const port = 8080;
const baseURL = `http://${host}:${port}/api/v1`;

const client = axios.create({
  baseURL,
  timeout: 30000,
});

// Request interceptor for Auth/Device headers
client.interceptors.request.use((config) => {
  const pin = sessionStorage.getItem('X-Pin');
  const deviceId = localStorage.getItem('X-Device-Id');

  if (pin) config.headers['X-Pin'] = pin;
  if (deviceId) config.headers['X-Device-Id'] = deviceId;

  return config;
});

// Response interceptor for 401
client.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      window.dispatchEvent(new CustomEvent('ls:auth-required'));
    }
    return Promise.reject(error);
  }
);

export const setPin = (pin: string) => {
  sessionStorage.setItem('X-Pin', pin);
};

export default client;
