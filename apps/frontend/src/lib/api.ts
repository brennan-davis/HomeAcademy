import axios from 'axios'

// TODO: This is your central API client.
// All backend calls should go through here.
// Add request/response interceptors for:
//   - Attaching the JWT token to every request
//   - Redirecting to /login on 401 responses
//   - Global error handling/toast notifications

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3001',
})

// TODO: Add interceptors
// api.interceptors.request.use(...)
// api.interceptors.response.use(...)
