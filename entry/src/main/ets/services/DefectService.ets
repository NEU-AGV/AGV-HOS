// /entry/src/main/ets/services/DefectService.ets

import http from '@ohos.net.http';
import { Defect } from '../model/Defect';
import { Task } from '../model/Task';

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
  taskName: string;
  taskId: string;
  description: string;
  defectType: string;
  severity: '高' | '中' | '低';
  discoverer: string;
  imageUrl: string;
  discoveryTime: string;
}

// Switch to true to simulate API calls, false to use local mock data
const USE_REAL_API = false;
const BASE_URL = 'https://your.api.backend.com'; // Replace with your actual API endpoint

// Mock data source transcribed from DefectManagement.vue
const mockDataSource: Defect[] = [
  { id: 1, defectId: 'DEF-2024-001', taskId: 'TASK-20250626-001', taskName: '1号线隧道巡检', defectType: '裂缝', description: '隧道壁K125+600处发现横向裂缝，长约2.5米。', imageUrl: 'https://fuss10.elemecdn.com/e/5d/4a731a90594a4af544c0c25941171jpeg.jpeg', severity: '中', isVerified: true, currentStatus: '已整改', discoverer: '李四', discoveryTime: '2025-06-26 10:30', discoveryMethod: '人工巡检', confirmer: '王主管', confirmationTime: '2025-06-26 14:00', handler: '维修一队', handlingStartTime: '2025-06-27 09:00', handlingCompletionTime: '2025-06-27 17:30', handlingResult: '已使用高标号水泥砂浆进行封堵修复。'},
  { id: 2, defectId: 'DEF-2024-002', taskId: 'TASK-20250627-001', taskName: '2号线设备检查', defectType: '渗水', description: '接触网支撑结构附近有明显水渍和滴漏。', imageUrl: 'https://fuss10.elemecdn.com/1/34/19aa98b1fcb2781c4fba33d850549jpeg.jpeg', severity: '高', isVerified: true, currentStatus: '处理中', discoverer: '赵六', discoveryTime: '2025-06-26 15:45', discoveryMethod: '例行检查', confirmer: '王主管', confirmationTime: '2025-06-27 09:00', handler: '抢修二队', handlingStartTime: '2025-06-28 10:00', handlingCompletionTime: '', handlingResult: ''},
  { id: 3, defectId: 'DEF-2024-003', taskId:'',taskName: '3号线日常巡视', defectType: '设备故障', description: '信号机S-34无显示，疑似电源故障。', imageUrl: 'https://fuss10.elemecdn.com/0/6f/e35ff375812e6b0020b6b4e8f9583jpeg.jpeg', severity: '高', isVerified: true, currentStatus: '已确认', discoverer: '吴八', discoveryTime: '2025-06-25 09:15', discoveryMethod: '人工巡检', confirmer: '刘工', confirmationTime: '2025-06-25 10:00', handler: '', handlingStartTime: '', handlingCompletionTime: '', handlingResult: ''},
  { id: 4, defectId: 'DEF-2024-004',taskId:'', taskName: '1号线隧道巡检', defectType: '照明问题', description: 'K130附近连续3盏照明灯不亮。', imageUrl: 'https://fuss10.elemecdn.com/a/3f/3302e58f9a181d2509f3dc0fa68b0jpeg.jpeg', severity: '低', isVerified: true, currentStatus: '待确认', discoverer: '李四', discoveryTime: '2025-06-25 11:20', discoveryMethod: '人工巡检', confirmer: '', confirmationTime: '', handler: '', handlingStartTime: '', handlingCompletionTime: '', handlingResult: ''},
];

class DefectService {

  // Corresponds to getDefects in defects.js
  async getDefects(params: GetDefectsParams): Promise<GetDefectsResponse> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();
      // This is a simplified GET request. You'd need to properly build the URL with params.
      const response = await httpRequest.request(`${BASE_URL}/defects?page=${params.currentPage}&pageSize=${params.pageSize}`);
      return JSON.parse(response.result as string);
    } else {
      // Mock filtering logic from DefectManagement.vue
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
        }, 500); // Simulate network delay
      });
    }
  }

  // Corresponds to addDefect in defects.js
  async addDefect(data:  AddDefectData): Promise<void> {
    if (USE_REAL_API) {
      const httpRequest = http.createHttp();
      await httpRequest.request(`${BASE_URL}/defects`, {
        method: http.RequestMethod.POST,
        extraData: JSON.stringify(data)
      });
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
      await httpRequest.request(`${BASE_URL}/defects/${defectId}/status`, {
        method: http.RequestMethod.PUT,
        extraData: { status }
      });
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

  // Corresponds to "获取可选任务列表" requirement
  async getTasks(): Promise<Task[]> {
    if (USE_REAL_API) {
      // Implement real API call here
      return [];
    } else {
      // 修改点 3：在 map 中明确返回 Task 类型
      const allTasks: Task[] = mockDataSource.map((item: Defect): Task => {
        const task: Task = {
          taskId: item.taskId,
          taskName: item.taskName
        };
        return task;
      });

      // 修改点 4：使用更兼容的方式去重，避免使用扩展运算符和属性索引
      const uniqueTasksMap = new Map<string, Task>();
      for (const task of allTasks) {
        // 使用点操作符访问属性
        if (!uniqueTasksMap.has(task.taskId)) {
          uniqueTasksMap.set(task.taskId, task);
        }
      }

      const result: Task[] = [];
      for(const task of uniqueTasksMap.values()){
        result.push(task);
      }
      return result;
    }
  }
}

export default new DefectService();