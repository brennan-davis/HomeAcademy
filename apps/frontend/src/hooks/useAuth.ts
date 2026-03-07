import { useState, useEffect } from 'react'
import { api } from '../lib/api'

interface User {
  id: string
  email: string
  role: 'ADMIN' | 'PARENT' | 'STUDENT'
}

export const useAuth = () => {
  const [token, setToken] = useState<string | null>(localStorage.getItem('authToken'))
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchUser = async () => {
      if (token) {
        try {
          const response = await api.get('/auth/me')
          setUser(response.data.user)
        } catch (error) {
          console.error('Failed to fetch user:', error)
          setToken(null)
          localStorage.removeItem('authToken')
        }
      }
      setLoading(false)
    }

    fetchUser()
  }, [token])

  const login = (newToken: string) => {
    localStorage.setItem('authToken', newToken)
    setToken(newToken)
  }

  const logout = () => {
    localStorage.removeItem('authToken')
    setToken(null)
    setUser(null)
    window.location.href = '/login'
  }

  return {
    token,
    user,
    loading,
    login,
    logout,
    isAuthenticated: !!token && !!user,
  }
}
