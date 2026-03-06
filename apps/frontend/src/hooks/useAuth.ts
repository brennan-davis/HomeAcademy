// TODO: Build this out as part of Step 1 (Auth)
// This hook should:
//   - Store the JWT token in localStorage
//   - Expose login(), logout(), and the current user
//   - Be used by ProtectedRoute to guard pages

export const useAuth = () => {
  // TODO: implement me
  return {
    token: null as string | null,
    user: null,
    login: (_token: string) => {},
    logout: () => {},
  }
}
