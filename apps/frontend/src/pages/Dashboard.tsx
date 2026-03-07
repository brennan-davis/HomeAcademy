import { useAuth } from '../hooks/useAuth'

export default function Dashboard() {
  const { user, logout, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <p className="text-gray-600">Loading...</p>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-white shadow rounded-lg p-8">
          <div className="text-center space-y-6">
            <h1 className="text-4xl font-bold text-primary-700">
              🏫 Welcome to HomeAcademy!
            </h1>
            
            {user && (
              <div className="space-y-2">
                <p className="text-xl text-gray-700">
                  Hello, <span className="font-semibold">{user.email}</span>
                </p>
                <p className="text-sm text-gray-500">
                  Role: <span className="font-medium text-gray-700">{user.role}</span>
                </p>
              </div>
            )}

            <div className="pt-4">
              <button
                onClick={logout}
                className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
