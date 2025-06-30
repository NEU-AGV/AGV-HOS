// /entry/src/main/ets/pages/DefectDetailPage.ets

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Defect } from '../model/Defect';
import DefectService from '../services/ApiService';

// 新增：为页面路由参数定义接口
interface DetailPageParams {
  defect: string;
}

@Component
struct DetailItem {
  // 修改：为所有属性提供默认初始值，以满足严格的编译器检查
  label: string = '';
  value: string | undefined = undefined;

  build() {
    Row() {
      Text(this.label)
        .width(120)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.End)
        .margin({ right: 10 })
      Text(this.value || '-')
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .padding(10)
    .border({ width: { bottom: 1 }, color: '#eee' })
  }
}

// 修改点 3：用代码绘制一个返回图标
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
struct DefectDetailPage {
  // 修改点 2：安全地获取路由参数
  private params = router.getParams() as DetailPageParams;
  @State defect: Defect = JSON.parse(this.params.defect);

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

      Scroll() {
        Column({ space: 15 }) {
          // Defect Image
          Image(this.defect.imageUrl)
            .width('100%').height(240)
            .objectFit(ImageFit.Contain)
            .backgroundColor(Color.Black)
            .borderRadius(8)

          // Basic Info Section
          Column() {
            Text('基础信息').fontSize(18).fontWeight(500).width('100%').padding(5)
            DetailItem({ label: '缺陷编号', value: this.defect.defectId })
            DetailItem({ label: '缺陷类型', value: this.defect.defectType })
            DetailItem({ label: '严重程度', value: this.defect.severity })
            DetailItem({ label: '缺陷描述', value: this.defect.description })
          }
          .backgroundColor('#fff').borderRadius(8)

          // Handling Info Section
          Column() {
            Text('发现与处理信息').fontSize(18).fontWeight(500).width('100%').padding(5)
            DetailItem({ label: '当前状态', value: this.defect.currentStatus })
            DetailItem({ label: '关联任务', value: this.defect.taskName })
            DetailItem({ label: '发现人员', value: this.defect.discoverer })
            DetailItem({ label: '发现时间', value: this.defect.discoveryTime })
            DetailItem({ label: '处理人员', value: this.defect.handler })
            DetailItem({ label: '处理完成时间', value: this.defect.handlingCompletionTime })
            DetailItem({ label: '处理结果', value: this.defect.handlingResult })
          }
          .backgroundColor('#fff').borderRadius(8)

          // Action Button - Corresponds to handleMarkAsRectified
          if (this.defect.currentStatus !== '已整改') {
            Button('标记为已整改')
              .width('100%').height(45).type(ButtonType.Capsule)
              .onClick(async () => {
                await DefectService.updateDefectStatus(this.defect.defectId, '已整改');
                promptAction.showToast({ message: '状态更新成功！' });
                // Update local state to reflect change
                this.defect.currentStatus = '已整改';
              })
              .margin({ top: 20 })
          }
        }
        .padding(10)
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#f0f2f5')
  }
}