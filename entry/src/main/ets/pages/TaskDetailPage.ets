// /entry/src/main/ets/pages/TaskDetailPage.ets

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Task } from '../model/Task';
import ApiService from '../services/ApiService';

// --- 复用自 DefectDetailPage 的辅助组件 ---
interface TaskDetailPageParams {
  task: string;
}

@Component
struct DetailItem {
  label: string = '';
  value: string | number | undefined;

  build() {
    Row() {
      Text(this.label)
        .width(120)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.End)
        .margin({ right: 10 })
      Text(this.value ? `${this.value}` : '-') // 统一转为 string 显示
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .padding(10)
    .border({ width: { bottom: 1 }, color: '#eee' })
  }
}

@Component
struct BackIcon {
  iconSize: number = 24
  iconColor: ResourceColor = Color.Black
  iconStrokeWidth: number = 3

  build() {
    Path({ width: this.iconSize, height: this.iconSize })
      .commands(`M ${this.iconSize * 0.7} 0 L ${this.iconSize * 0.1} ${this.iconSize / 2} L ${this.iconSize * 0.7} ${this.iconSize}`)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
      .strokeLineJoin(LineJoinStyle.Round)
      .strokeLineCap(LineCapStyle.Round)
  }
}
// --- 辅助组件结束 ---
@Entry
@Component
struct TaskDetailPage {
  private params = router.getParams() as TaskDetailPageParams;
  @State task: Task = JSON.parse(this.params.task);

  build() {
    Column() {
      // Header
      Row() {
        BackIcon({ iconSize: 22, iconColor: '#333', iconStrokeWidth: 2.5 })
          .padding(8)
          .onClick(() => router.back())
        Text('任务详情')
          .fontSize(22).fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%').height(56)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 15 }) {
          DetailItem({ label: '任务ID', value: this.task.taskId })
          DetailItem({ label: '任务名称', value: this.task.taskName })
          DetailItem({ label: '任务类型', value: this.task.taskType })
          DetailItem({ label: '优先级', value: this.task.priority })
          DetailItem({ label: '描述', value: this.task.description })
          DetailItem({ label: '创建人', value: this.task.creator })
          DetailItem({ label: '执行人', value: this.task.executor })
          DetailItem({ label: '计划开始时间', value: this.task.plannedStartTime })
          DetailItem({ label: '计划结束时间', value: this.task.plannedEndTime })
          DetailItem({ label: '实际开始时间', value: this.task.actualStartTime })
          DetailItem({ label: '实际结束时间', value: this.task.actualEndTime })
          DetailItem({ label: '任务状态', value: this.task.status })
          DetailItem({ label: '完成度', value: `${this.task.progress}%` })
          DetailItem({ label: '发现问题数', value: this.task.problemsFound })
          DetailItem({ label: '执行结果', value: this.task.result })

          // 操作按钮
          Row({ space: 10 }) {
            Button('关闭')
              .onClick(() => router.back())
              .layoutWeight(1).type(ButtonType.Normal)

            Button('删除任务')
              .onClick(async () => {
                // 弹出确认对话框
                const confirm = await promptAction.showDialog({
                  title: '确认删除',
                  message: `确定要删除任务 "${this.task.taskName}" 吗？`,
                  buttons: [
                    { text: '取消', color: '#000000' },
                    { text: '删除', color: '#ff0000' }
                  ]
                });
                if (confirm.index === 1) { // 用户点击了“删除”
                  await ApiService.deleteTask(this.task.id);
                  promptAction.showToast({ message: '任务删除成功' });
                  router.back();
                }
              })
              .layoutWeight(1).type(ButtonType.Capsule).backgroundColor(Color.Red)
          }.width('100%').margin({ top: 20 })
        }
        .padding(10)
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#f0f2f5')
  }
}