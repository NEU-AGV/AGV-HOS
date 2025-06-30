// /entry/src/main/ets/pages/AddDefectPage.ets

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Task } from '../model/Task';
import DefectService from '../services/ApiService';

// 新增：为 Select 组件的选项定义一个标准接口
interface SelectOption {
  value: string;
}

@Component
struct FormItem {
  label: string = '';
  @BuilderParam content: () => void;

  build() {
    Row() {
      Text(this.label).width(100).textAlign(TextAlign.End)
      this.content()
    }
    .padding(10).height(60)
    .alignItems(VerticalAlign.Center)
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
  @State severity: string = '低';
  @State discoverer: string = '';
  // In a real app, imageUrl would be handled by a file picker
  @State imageUrl: string = 'https://fuss10.elemecdn.com/a/3f/3302e58f9a181d2509f3dc0fa68b0jpeg.jpeg';

  async aboutToAppear() {
    // Fulfills the requirement to get tasks for the form
    this.tasks = await DefectService.getTasks();
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
        taskName: this.tasks[this.selectedTaskIndex].taskName,
        taskId: this.tasks[this.selectedTaskIndex].taskId,
        description: this.description,
        defectType: this.defectType,
        severity: this.severity as ('高' | '中' | '低'),
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
          Select([{ value: '高' }, { value: '中' }, { value: '低' }])
            .selected(1) // Default to '中'
            .onSelect(idx => this.severity = ['高', '中', '低'][idx])
            .layoutWeight(1)
        }
        FormItem({ label: '发现人员' }) {
          TextInput({ placeholder: '请输入发现人员姓名' })
            .onChange(val => this.discoverer = val)
            .layoutWeight(1)
        }

        Text('缺陷描述').width('100%').padding(10)
        TextArea({ placeholder: '请详细描述缺陷情况...' })
          .height(120)
          .onChange(val => this.description = val)
          .margin({ left: 10, right: 10 })

        Button('提交缺陷')
          .width('95%').height(45)
          .margin({ top: 30 })
          .onClick(() => this.handleSubmit())
      }
      .padding(10)
      .backgroundColor('#fff')
      .borderRadius(8)
      .margin(10)
    }
    .width('100%').height('100%').backgroundColor('#f0f2f5')
  }
}