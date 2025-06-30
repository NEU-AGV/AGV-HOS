// /entry/src/main/ets/model/Task.ets

// Based on the mockDataSource in CalendarView.vue
export interface Task {
  id: number;
  taskId: string;
  taskName: string;
  taskType: string;
  priority: '高' | '中' | '低';
  description: string;
  creator: string;
  executor: string;
  helper: string;
  plannedStartTime: string;
  plannedEndTime: string;
  actualStartTime: string;
  actualEndTime: string;
  line: string;
  startLocation: string;
  endLocation: string;
  scope: string;
  status: '已完成' | '进行中' | '待执行' | '已暂停' | '已取消';
  progress: number;
  result: string;
  problemsFound: number;
  uploadTime: string;
}