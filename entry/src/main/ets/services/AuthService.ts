// /entry/src/main/ets/services/AuthService.ts

class AuthService {
  private token: string | null = null;

  // 保存 Token
  setToken(token: string): void {
    this.token = token;
    // (可选) 如果需要持久化，可以在这里使用 @ohos.data.storage 保存到本地
  }

  // 获取 Token
  getToken(): string | null {
    // (可选) 如果做了持久化，可以先尝试从 @ohos.data.storage 读取
    return this.token;
  }

  // 清除 Token (用于退出登录)
  clearToken(): void {
    this.token = null;
    // (可选) 同时清除持久化存储的 token
  }

  // 判断是否已登录
  isLoggedIn(): boolean {
    return !!this.token;
  }
}

// 使用单例模式，确保应用中只有一个 AuthService 实例
const authService = new AuthService();
export default authService;