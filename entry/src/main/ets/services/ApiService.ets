// /entry/src/main/ets/services/DefectService.ets

import http from '@ohos.net.http';
import { Defect } from '../model/Defect';
import { Task } from '../model/Task';
import authService from './AuthService';

// 新增：为 getDefects 的参数创建一个接口
interface GetDefectsParams {
  currentPage: number;
  pageSize: number;
  taskName?: string;
  defectType?: string;
  severity?: string;
  currentStatus?: string;
}
// 新增：为 getDefects 的返回值创建一个接口
interface GetDefectsResponse {
  list: Defect[];
  total: number;
}
// 新增：为 addDefect 的参数创建一个接口，替代 Omit
interface AddDefectData {
  defectId: string;
  taskName: string;
  taskId: string;
  description: string;
  defectType: string;
  severity: '高' | '中' | '低';
  currentStatus: '待确认' | '已确认' | '处理中' | '已整改';
  discoverer: string;
  imageUrl: string;
  discoveryTime: string;
}

// --- Task Service Interfaces ---
// 对应 getTasks 的参数
interface GetTasksParams {
  startDate: string;
  endDate: string;
}
// 修正1：修改接口以匹配后端真实的返回结构（records）
interface GetTasksResponse {
  records: Task[]; // 将 list 修改为 records
  total?: number;
  size?: number;
  current?: number;
  pages?: number;
}
// 新增：为后端返回的最外层结构定义一个通用接口
interface ApiResponse<T> {
  code: number;
  message: string;
  data: T; // 使用泛型，T 可以是 GetDefectsResponse 或 GetTasksResponse
}

// --- 新增用户相关的接口定义 ---
interface LoginParams {
  username: string;
  password?: string;
  captcha: string;
  uuid: string;
}

interface LoginResponse {
  token: string;
}

interface CaptchaResponse {
  uuid: string;
  img: string; // Base64 格式的图片
}

// Switch to true to simulate API calls, false to use local mock data
const USE_REAL_API = true;
const BASE_URL = 'http://172.22.49.179:8080'; // Replace with your actual API endpoint

// Mock data source transcribed from DefectManagement.vue
const mockDataSource: Defect[] = [
  { id: 1, defectId: 'DEF-2024-001', taskId: 'TASK-20250626-001', taskName: '1号线隧道巡检', defectType: '裂缝', description: '隧道壁K125+600处发现横向裂缝，长约2.5米。', imageUrl: 'https://fuss10.elemecdn.com/e/5d/4a731a90594a4af544c0c25941171jpeg.jpeg', severity: '中', isVerified: true, currentStatus: '已整改', discoverer: '李四', discoveryTime: '2025-06-26 10:30', discoveryMethod: '人工巡检', confirmer: '王主管', confirmationTime: '2025-06-26 14:00', handler: '维修一队', handlingStartTime: '2025-06-27 09:00', handlingCompletionTime: '2025-06-27 17:30', handlingResult: '已使用高标号水泥砂浆进行封堵修复。'},
  { id: 2, defectId: 'DEF-2024-002', taskId: 'TASK-20250627-001', taskName: '2号线设备检查', defectType: '渗水', description: '接触网支撑结构附近有明显水渍和滴漏。', imageUrl: 'https://fuss10.elemecdn.com/1/34/19aa98b1fcb2781c4fba33d850549jpeg.jpeg', severity: '高', isVerified: true, currentStatus: '处理中', discoverer: '赵六', discoveryTime: '2025-06-26 15:45', discoveryMethod: '例行检查', confirmer: '王主管', confirmationTime: '2025-06-27 09:00', handler: '抢修二队', handlingStartTime: '2025-06-28 10:00', handlingCompletionTime: '', handlingResult: ''},
  { id: 3, defectId: 'DEF-2024-003', taskId:'',taskName: '3号线日常巡视', defectType: '设备故障', description: '信号机S-34无显示，疑似电源故障。', imageUrl: 'https://fuss10.elemecdn.com/0/6f/e35ff375812e6b0020b6b4e8f9583jpeg.jpeg', severity: '高', isVerified: true, currentStatus: '已确认', discoverer: '吴八', discoveryTime: '2025-06-25 09:15', discoveryMethod: '人工巡检', confirmer: '刘工', confirmationTime: '2025-06-25 10:00', handler: '', handlingStartTime: '', handlingCompletionTime: '', handlingResult: ''},
  { id: 4, defectId: 'DEF-2024-004',taskId:'', taskName: '1号线隧道巡检', defectType: '照明问题', description: 'K130附近连续3盏照明灯不亮。', imageUrl: 'https://fuss10.elemecdn.com/a/3f/3302e58f9a181d2509f3dc0fa68b0jpeg.jpeg', severity: '低', isVerified: true, currentStatus: '待确认', discoverer: '李四', discoveryTime: '2025-06-25 11:20', discoveryMethod: '人工巡检', confirmer: '', confirmationTime: '', handler: '', handlingStartTime: '', handlingCompletionTime: '', handlingResult: ''},
];
//任务管理的模拟数据
const mockTasks: Task[] = [
  { id: 1, taskId: 'TASK-20250626-001', taskName: '1号线隧道巡检', taskType: '例行巡检', priority: '高', description: '对1号线K10-K15段进行全面结构巡检。', creator: '张三', executor: '李四', helper: '王二麻子', plannedStartTime: '2025-06-26 09:00', plannedEndTime: '2025-06-26 12:00', actualStartTime: '2025-06-26 09:05', actualEndTime: '2025-06-26 11:45', line: '1号线', startLocation: 'K10', endLocation: 'K15', scope: '全断面', status: '已完成', progress: 100, result: '巡检完成，发现3处轻微裂缝。', problemsFound: 3, uploadTime: '2025-06-26 13:00' },
  { id: 2, taskId: 'TASK-20250627-001', taskName: '2号线设备检查', taskType: '专项检查', priority: '中', description: '检查2号线信号机S5-S8状态。', creator: '王五', executor: '赵六', helper: '孙七', plannedStartTime: '2025-06-27 14:00', plannedEndTime: '2025-06-27 16:00', actualStartTime: '2025-06-27 14:10', actualEndTime: '', line: '2号线', startLocation: 'S5信号机', endLocation: 'S8信号机', scope: '信号设备', status: '进行中', progress: 60, result: '正在处理中...', problemsFound: 1, uploadTime: '' },
  { id: 3, taskId: 'TASK-20250628-001', taskName: '3号线日常巡视', taskType: '日常巡视', priority: '低', description: '3号线全线轨道异物巡视。', creator: '陈七', executor: '吴八', helper: '周九', plannedStartTime: '2025-06-28 08:30', plannedEndTime: '2025-06-28 12:30', actualStartTime: '', actualEndTime: '', line: '3号线', startLocation: '始发站', endLocation: '终点站', scope: '轨道面', status: '待执行', progress: 0, result: '', problemsFound: 0, uploadTime: '' },
];

class ApiService {

  // --- 新增：用户认证方法 ---

  // 关键修正：适配后端返回的 {code, message, data:{uuid, img}} 结构
  async getCaptcha(): Promise<CaptchaResponse> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/captcha`, {
        method: http.RequestMethod.GET
      });

      console.info('API_DEBUG', `Raw Captcha Response: ${response.result}`);

      if (response.responseCode === http.ResponseCode.OK && typeof response.result === 'string') {
        // 解析最外层的 ApiResponse，其 data 字段的类型是 CaptchaResponse
        const parsedResult = JSON.parse(response.result as string) as ApiResponse<CaptchaResponse>;

        // 检查 data 字段及其内部的属性是否存在
        if (parsedResult && parsedResult.data && parsedResult.data.uuid && parsedResult.data.img) {
          // 返回 data 字段，这才是我们真正需要的数据
          return parsedResult.data;
        }
      }
      console.error('API_DEBUG', `getCaptcha: Backend response format is incorrect.`);
    } catch (error) {
      console.error('API_DEBUG', `Exception during getCaptcha request: ${JSON.stringify(error)}`);
    }
    // 所有失败路径最终都会抛出异常
    throw new Error("获取验证码失败");
  }

  // 关键修正：适配后端返回的 {code, data: {token}} 结构
  async login(data: LoginParams): Promise<LoginResponse> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${BASE_URL}/login`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(data)
      });

      console.info('API_DEBUG', `Raw Login Response: ${response.result}`);

      if (response.responseCode === http.ResponseCode.OK && typeof response.result === 'string') {
        const parsedResult = JSON.parse(response.result as string) as ApiResponse<LoginResponse>;
        // 检查 code 是否为200，并从 data 字段里取 token
        if (parsedResult && parsedResult.code === 200 && parsedResult.data && parsedResult.data.token) {
          return parsedResult.data; // 返回包含 token 的 data 对象
        } else {
          // 如果 code 不是 200 或数据结构不对，抛出后端返回的错误信息
          throw new Error(parsedResult.message || '登录失败');
        }
      }
    } catch(error) {
      console.error('API_DEBUG', `Exception during login request: ${JSON.stringify(error)}`);
      throw new Error(JSON.stringify(error));
    }
    throw new Error('登录请求失败，请检查网络');
  }

  // Corresponds to getDefects in defects.js
  async getDefects(params: GetDefectsParams): Promise<GetDefectsResponse> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();

      // 关键修正：对所有查询参数进行URL编码
      const taskName = encodeURIComponent(params.taskName || '');
      const defectType = encodeURIComponent(params.defectType || '');
      const severity = encodeURIComponent(params.severity || '');
      const currentStatus = encodeURIComponent(params.currentStatus || '');

      const url = `${BASE_URL}/defects?page=${params.currentPage}&pageSize=${params.pageSize}&taskName=${taskName}&defectType=${defectType}&severity=${severity}&currentStatus=${currentStatus}`;

      try {
        const headers: Record<string, string> = {};
        const token = authService.getToken();
        if (token) {
          headers['Authorization'] = token;
        }

        const response = await httpRequest.request(url, {
          method: http.RequestMethod.GET,
          header: headers
        });

        console.info('API_DEBUG', `Raw response from getDefects: ${response.result}`);
        if (response.responseCode === http.ResponseCode.OK && typeof response.result === 'string' && response.result.length > 0) {
          const parsedResult = JSON.parse(response.result as string) as ApiResponse<GetDefectsResponse>;
          if (parsedResult && parsedResult.data && Array.isArray(parsedResult.data.list)) {
            return parsedResult.data;
          }
        }
        return { list: [], total: 0 };
      } catch (error) {
        console.error('API_DEBUG', `getDefects: Exception: ${JSON.stringify(error)}`);
        return { list: [], total: 0 };
      }
    } else {
      return new Promise((resolve) => {
        setTimeout(() => {
          const filteredData = mockDataSource.filter(item => {
            return (
              (item.taskName.includes(params.taskName || '')) &&
                (item.defectType.includes(params.defectType || '')) &&
                (!params.severity || item.severity === params.severity) &&
                (!params.currentStatus || item.currentStatus === params.currentStatus)
            );
          });
          const total = filteredData.length;
          const start = (params.currentPage - 1) * params.pageSize;
          const end = start + params.pageSize;
          const list = filteredData.slice(start, end);
          const responseData: GetDefectsResponse = { list, total };
          resolve(responseData);
        }, 500);
      });
    }
  }

  // Corresponds to addDefect in defects.js
  async addDefect(data: AddDefectData): Promise<void> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();
      try {
        // 修正：使用 Record<string, string> 作为 header 的类型
        const headers: Record<string, string> = {
          'Content-Type': 'application/json'
        };
        const token = authService.getToken();
        if (token) {
          headers['Authorization'] = token;
        }

        await httpRequest.request(`${BASE_URL}/defects`, {
          method: http.RequestMethod.POST,
          header: headers,
          extraData: JSON.stringify(data)
        });
      } catch (error) {
        console.error('API_DEBUG', `addDefect: Exception: ${JSON.stringify(error)}`);
      }
    } else {
      return new Promise(resolve => {
        setTimeout(() => {
          const newId = Math.max(...mockDataSource.map(d => d.id)) + 1;
          const newDefect: Defect = {
            id: newId,
            defectId: `DEF-2024-${String(newId).padStart(3, '0')}`,
            taskId: data.taskId,
            taskName: data.taskName,
            defectType: data.defectType,
            description: data.description,
            imageUrl: data.imageUrl,
            severity: data.severity,
            discoverer: data.discoverer,
            discoveryTime: data.discoveryTime,
            isVerified: false,
            currentStatus: '待确认',
            discoveryMethod: '人工录入',
            confirmer: '',
            confirmationTime: '',
            handler: '',
            handlingStartTime: '',
            handlingCompletionTime: '',
            handlingResult: ''
          };
          mockDataSource.unshift(newDefect);
          console.log('Added new defect (mock):', JSON.stringify(newDefect));
          resolve();
        }, 300);
      });
    }
  }

  // Corresponds to updateDefectStatus in defects.js
  async updateDefectStatus(defectId: string, status: '已整改'): Promise<void> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();
      try {
        // 修正：使用 Record<string, string> 作为 header 的类型
        const headers: Record<string, string> = {
          'Content-Type': 'application/json'
        };
        const token = authService.getToken();
        if (token) {
          headers['Authorization'] = token;
        }

        await httpRequest.request(`${BASE_URL}/defects/${defectId}/status`, {
          method: http.RequestMethod.PUT,
          header: headers,
          extraData: JSON.stringify({ status: status })
        });
      } catch (error) {
        console.error('API_DEBUG', `updateDefectStatus: Exception: ${JSON.stringify(error)}`);
      }
    } else {
      return new Promise(resolve => {
        const item = mockDataSource.find(d => d.defectId === defectId);
        if (item) {
          item.currentStatus = status;
          item.handlingCompletionTime = new Date().toISOString().slice(0, 16).replace('T', ' ');
        }
        resolve();
      });
    }
  }

  /**
   * 获取任务列表 (支持按日期范围筛选)
   * @param params
   */
  async getTasks(params?: GetTasksParams): Promise<Task[]> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();
      const url = `${BASE_URL}/tasks?startDate=${params?.startDate || ''}&endDate=${params?.endDate || ''}`;
      try {
        // 修正：使用 Record<string, string> 作为 header 的类型
        const headers: Record<string, string> = {};
        const token = authService.getToken();
        if (token) {
          headers['Authorization'] = token;
        }

        const response = await httpRequest.request(url, {
          method: http.RequestMethod.GET,
          header: headers
        });

        if (response.responseCode === http.ResponseCode.OK && typeof response.result === 'string' && response.result.length > 0) {
          const parsedResult = JSON.parse(response.result as string) as ApiResponse<GetTasksResponse>;

          // 修正2：检查 parsedResult.data.records 是否为数组
          if (parsedResult && parsedResult.data && Array.isArray(parsedResult.data.records)) {
            // 修正3：返回 records 数组
            return parsedResult.data.records;
          } else {
            console.error('API_DEBUG', 'getTasks: Backend response "data" field is incorrect, expected a "records" array.');
            return [];
          }
        } else {
          console.error('API_DEBUG', `getTasks: Request failed. Code: ${response.responseCode}`);
          return [];
        }
      } catch (error) {
        console.error('API_DEBUG', `getTasks: Exception: ${JSON.stringify(error)}`);
        return [];
      }
    } else {
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve(mockTasks);
        }, 300);
      });
    }
  }
  /**
   * 删除一个任务
   * @param taskId
   */
  /**
   * 删除一个任务
   * @param id - 任务的数字ID
   */
  async deleteTask(id: number): Promise<void> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();
      try {
        const headers: Record<string, string> = {};
        const token = authService.getToken();
        if (token) {
          // 修正：直接发送原始token，不再添加 "Bearer " 前缀
          headers['Authorization'] = token;
        }
        await httpRequest.request(`${BASE_URL}/tasks/${id}`, {
          method: http.RequestMethod.DELETE,
          header: headers
        });
      } catch (error) {
        console.error('API_DEBUG', `deleteTask: Exception: ${JSON.stringify(error)}`);
      }
    }
  }


  getAuthHeader(): Object | undefined {
    throw new Error('Method not implemented.');
  }
}


export default new ApiService();