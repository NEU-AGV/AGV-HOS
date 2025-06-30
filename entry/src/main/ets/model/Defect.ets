// /entry/src/main/ets/model/Defect.ets

// Based on the mockDataSource in DefectManagement.vue
export interface Defect {
  id: number;
  defectId: string;
  taskId: string;
  taskName: string;
  defectType: string;
  description: string;
  imageUrl: string;
  severity: '高' | '中' | '低';
  isVerified: boolean;
  currentStatus: '待确认' | '已确认' | '处理中' | '已整改';
  discoverer: string;
  discoveryTime: string;
  discoveryMethod: string;
  confirmer: string;
  confirmationTime: string;
  handler: string;
  handlingStartTime: string;
  handlingCompletionTime: string;
  handlingResult: string;
}