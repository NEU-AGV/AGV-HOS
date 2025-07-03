// /entry/src/main/ets/pages/AddDefectPage.ets

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Task } from '../model/Task';
import DefectService from '../services/ApiService';
import ApiService from '../services/ApiService';

// 新增：为 Select 组件的选项定义一个标准接口
interface SelectOption {
  value: string;
}
// 修正：将 FormItem 和 BackIcon 提取出来，保持页面主组件的整洁
@Component
struct FormItem {
  label: string = '';
  @BuilderParam content: () => void;

  build() {
    Row() {
      Text(this.label).width(100).textAlign(TextAlign.End).margin({ right: 12 }).fontSize(16)
      this.content()
    }
    .alignItems(VerticalAlign.Center)
    .padding({ top: 5, bottom: 5 })
    .height(60)
    .border({ width: { bottom: 1 }, color: '#f0f0f0' })
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

@Entry
@Component
struct AddDefectPage {
  @State tasks: Task[] = [];
  @State selectedTaskIndex: number = -1;
  @State description: string = '';
  @State defectType: string = '';
  @State severity: '高' | '中' | '低' = '低';
  @State discoverer: string = '';
  // In a real app, imageUrl would be handled by a file picker
  @State currentStatus: '待确认' | '已确认' | '处理中' | '已整改' = '待确认';
  @State imageUrl: string = 'https://fuss10.elemecdn.com/a/3f/3302e58f9a181d2509f3dc0fa68b0jpeg.jpeg';
  @State discoveryTime: string = '';

  private severityOptions: ('高' | '中' | '低')[] = ['高', '中', '低'];
  private statusOptions: ('待确认' | '已确认' | '处理中' | '已整改')[] = ['待确认', '已确认', '处理中', '已整改'];

  // 新增：自动生成 Defect ID 的方法
  generateDefectId(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const seconds = now.getSeconds().toString().padStart(2, '0');
    return `DEF-${year}${month}${day}-${hours}${minutes}${seconds}`;
  }

  async aboutToAppear() {
    if (!this.discoveryTime) {
      const now = new Date();
      const timezoneOffset = now.getTimezoneOffset() * 60000;
      const localTime = new Date(now.getTime() - timezoneOffset);
      this.discoveryTime = localTime.toISOString().slice(0, 16);
    }
    this.tasks = await ApiService.getTasks();
  }

  async handleSubmit() {
    if (this.selectedTaskIndex < 0) {
      promptAction.showToast({ message: '请选择关联任务' });
      return;
    }
    if (!this.description) {
      promptAction.showToast({ message: '请输入缺陷描述' });
      return;
    }

    try {
      await DefectService.addDefect({
        defectId: this.generateDefectId(),
        taskName: this.tasks[this.selectedTaskIndex].taskName,
        taskId: this.tasks[this.selectedTaskIndex].taskId,
        description: this.description,
        defectType: this.defectType,
        severity: this.severity ,
        currentStatus: this.currentStatus,
        discoverer: this.discoverer,
        imageUrl: this.imageUrl,
        discoveryTime: new Date().toISOString().slice(0, 16).replace('T', ' ')
      });
      promptAction.showToast({ message: '缺陷添加成功' });
      router.back();
    } catch (e) {
      promptAction.showToast({ message: `提交失败: ${JSON.stringify(e)}` });
    }
  }

  build() {
    Column() {
      // Header
      Row({ space: 10 }) {
        // 修改点 3：使用 BackIcon 组件
        BackIcon({ iconSize: 22, iconColor: '#333', iconStrokeWidth: 2.5 })
          .padding(8)
          .onClick(() => router.back())
        Text('缺陷详情')
          .fontSize(22).fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%').height(56)
      .alignItems(VerticalAlign.Center)

      // Form
      Scroll() {
      Column({ space: 5 }) {
        FormItem({ label: '关联任务' }) {
          Select(this.tasks.map((t: Task): SelectOption => {
            return { value: t.taskName };
          }))
            .selected(this.selectedTaskIndex)
            .onSelect(idx => this.selectedTaskIndex = idx)
            .layoutWeight(1)
        }

        FormItem({ label: '缺陷类型' }) {
          TextInput({ placeholder: '如：裂缝、渗水' })
            .onChange(val => this.defectType = val)
            .layoutWeight(1)
        }

        FormItem({ label: '严重程度' }) {
          Select(this.statusOptions.map((item: string): SelectOption => ({ value: item })))
            .value(this.severity)
            .selected(this.severityOptions.indexOf(this.severity))
            .onSelect((idx: number) => {
              this.severity = this.severityOptions[idx];
            })
            .layoutWeight(1) // 修正1：为Select添加layoutWeight
        }

        FormItem({ label: '缺陷状态' }) {
          Select(this.statusOptions.map((item: string): SelectOption => ({ value: item })))
            .value(this.currentStatus)
            .selected(this.statusOptions.indexOf(this.currentStatus))
            .onSelect((idx: number) => {
              this.currentStatus = this.statusOptions[idx];
            })
            .layoutWeight(1) // 修正1：为Select添加layoutWeight
        }

        FormItem({ label: '发现人员' }) {
          TextInput({ placeholder: '请输入发现人员姓名' })
            .onChange(val => this.discoverer = val)
            .layoutWeight(1)
        }

        FormItem({ label: '发现时间' }) {
          // 使用 DateTimePicker 来选择日期和时间
          DatePicker({
            start: new Date('2020-01-01'),
            end: new Date('2030-12-31'),
            selected: new Date(this.discoveryTime)
          })
            .onChange((value: DatePickerResult) => {
              // 关键修正1：在使用 value 的属性前，进行安全检查
              if (value && value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                // 关键修正2：DatePickerResult的month是1-12，所以要减1才能用于new Date()
                const newDate = new Date(value.year, value.month - 1, value.day);
                const timezoneOffset = newDate.getTimezoneOffset() * 60000;
                const localTime = new Date(newDate.getTime() - timezoneOffset);
                this.discoveryTime = localTime.toISOString().slice(0, 16);
              }
            })
        }

        Text('缺陷描述').width('100%').padding(10)
        TextArea({ placeholder: '请详细描述缺陷情况...' })
          .height(120)
          .onChange(val => this.description = val)
          .margin({ left: 10, right: 10 })
      }
      .padding({ left: 15, right: 15 })
      }
      .layoutWeight(1) // 让滚动区域占据中间所有可用空间
      .backgroundColor(Color.White)

        Button('提交缺陷')
          .width('95%').height(45)
          .margin({ top: 30 })
          .onClick(() => this.handleSubmit())
      }
      .padding(10)
      .backgroundColor('#fff')
      .borderRadius(8)
      .margin(10)
    .width('100%').height('100%').backgroundColor('#f0f2f5')
  }
}