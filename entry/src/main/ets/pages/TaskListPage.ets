// /entry/src/main/ets/pages/TaskListPage.ets

import router from '@ohos.router';
import { Task } from '../model/Task';
import ApiService from '../services/ApiService';

// 根据任务状态返回颜色
function getStatusColor(status: '已完成' | '进行中' | '待执行' | '已暂停' | '已取消'): ResourceColor {
  switch (status) {
    case '已完成': return '#67c23a';
    case '进行中': return '#409eff';
    case '待执行': return '#909399';
    default: return '#e6a23c';
  }
}

// 日历单元格的数据结构
interface CalendarDay {
  day: number;
  month: 'prev' | 'current' | 'next';
  tasks: Task[];
  date: Date;
}

@Entry
@Component
struct TaskListPage {
  @State allTasksInMonth: Task[] = [];
  @State selectedDateTasks: Task[] = [];
  @State displayYear: number = new Date().getFullYear();
  @State displayMonth: number = new Date().getMonth() + 1; // 1-12
  @State selectedDate: Date = new Date();
  @State today: Date = new Date(); // 用于高亮当天
  @State calendarDays: CalendarDay[] = [];

  aboutToAppear() {
    this.generateCalendar();
  }

  async generateCalendar() {
    await this.fetchTasksForMonth(this.displayYear, this.displayMonth);
    this.updateCalendarDays(this.displayYear, this.displayMonth);
  }

  async fetchTasksForMonth(year: number, month: number) {
    const startDate = new Date(year, month - 1, 1).toISOString().split('T')[0];
    const endDate = new Date(year, month, 0).toISOString().split('T')[0];
    try {
      this.allTasksInMonth = await ApiService.getTasks({ startDate, endDate });
      this.filterTasksForDate(this.selectedDate);
    } catch (e) {
      console.error('Failed to fetch tasks:', JSON.stringify(e));
    }
  }

  updateCalendarDays(year: number, month: number) {
    const days: CalendarDay[] = [];
    const firstDayOfMonth = new Date(year, month - 1, 1);
    const lastDayOfMonth = new Date(year, month, 0);
    const startDayOfWeek = firstDayOfMonth.getDay();
    const daysInMonth = lastDayOfMonth.getDate();

    const prevMonthLastDay = new Date(year, month - 1, 0).getDate();
    for (let i = startDayOfWeek; i > 0; i--) {
      const day = prevMonthLastDay - i + 1;
      days.push({ day, month: 'prev', tasks: [], date: new Date(year, month - 2, day) });
    }

    for (let i = 1; i <= daysInMonth; i++) {
      const currentDate = new Date(year, month - 1, i);
      const tasksOnDay = this.allTasksInMonth.filter(task => {
        const taskDate = new Date(task.plannedStartTime);
        return taskDate.getFullYear() === year && taskDate.getMonth() === (month - 1) && taskDate.getDate() === i;
      });
      days.push({ day: i, month: 'current', tasks: tasksOnDay, date: currentDate });
    }

    const remaining = 42 - days.length;
    for (let i = 1; i <= remaining; i++) {
      days.push({ day: i, month: 'next', tasks: [], date: new Date(year, month, i) });
    }
    this.calendarDays = days;
  }

  filterTasksForDate(date: Date) {
    this.selectedDate = date;
    const dayData = this.calendarDays.find(d => d.date.toDateString() === date.toDateString());
    if (dayData) {
      this.selectedDateTasks = dayData.tasks;
    }
  }

  changeMonth(delta: number) {
    let newMonth = this.displayMonth + delta;
    let newYear = this.displayYear;
    if (newMonth > 12) { newMonth = 1; newYear++; }
    if (newMonth < 1) { newMonth = 12; newYear--; }
    this.displayYear = newYear;
    this.displayMonth = newMonth;
    this.generateCalendar();
  }

  build() {
    Column() {
      // 1. 标题与模块切换
      Row() {
        Text('任务列表')
          .fontSize(24).fontWeight(FontWeight.Bold)

        // 使用 Blank 组件将按钮推到最右侧
        Blank()

        Button('缺陷管理')
          .onClick(() => {
            router.pushUrl({ url: 'pages/DefectListPage' })
          })
          .type(ButtonType.Capsule)
          .backgroundColor('#007DFF') // 使用一个醒目的颜色
      }
      .width('100%').padding(10). alignItems(VerticalAlign.Center)
      // 2. 月份切换器
      Row({ space: 20 }) {
        Button({ type: ButtonType.Circle, stateEffect: true }) { Text('<') }.onClick(() => this.changeMonth(-1)).backgroundColor(0xFFFFFF).fontColor(Color.Black)
        Text(`${this.displayYear}年 ${this.displayMonth}月`).fontSize(22).fontWeight(FontWeight.Bold)
        Button({ type: ButtonType.Circle, stateEffect: true }) { Text('>') }.onClick(() => this.changeMonth(1)).backgroundColor(0xFFFFFF).fontColor(Color.Black)
      }.padding({ top: 15, bottom: 15 }).width('100%').justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      // 3. 星期头部
      GridRow({ columns: 7, gutter: { x: 5 } }) {
        ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string) => {
          GridCol() { Text(day).width('100%').height(30).textAlign(TextAlign.Center).fontColor('#666666') }
        })
      }.padding({ bottom: 5 })

      // 4. 日期网格
      Grid() {
        ForEach(this.calendarDays, (item: CalendarDay) => {
          GridItem() {
            Column({ space: 3 }) {
              Text(item.day.toString())
                .fontColor(item.month === 'current' ? (this.today.toDateString() === item.date.toDateString() ? '#007DFF' : Color.Black) : Color.Gray)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)

              // 任务预览标签
              ForEach(item.tasks.slice(0, 2), (task: Task) => {
                Text(task.taskName)
                  .width('95%')
                  .fontSize(10)
                  .fontColor(Color.White)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .backgroundColor(getStatusColor(task.status))
                  .borderRadius(6)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              })

              // 任务过多时的提示
              if (item.tasks.length > 2) {
                Text(`+ ${item.tasks.length - 2} more`)
                  .fontSize(9).fontColor(Color.Gray).margin({ top: 2 })
              }
            }
            .width('100%')
            .height(85)
            .padding(5)
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.selectedDate.toDateString() === item.date.toDateString() ? '#e6f0ff' : '#f7f7f7')
            .borderRadius(8)
            .opacity(item.month === 'current' ? 1.0 : 0.4) // 非本月日期变淡
            .border({ // 高亮当天
              width: this.today.toDateString() === item.date.toDateString() ? 2 : 0,
              color: '#007DFF',
              radius: 8
            })
            .onClick(() => {
              if (item.month !== 'current') {
                this.displayYear = item.date.getFullYear();
                this.displayMonth = item.date.getMonth() + 1;
                this.generateCalendar();
              }
              this.filterTasksForDate(item.date);

              if (item.tasks.length === 1) {
                router.pushUrl({ url: 'pages/TaskDetailPage', params: { task: JSON.stringify(item.tasks[0]) } })
              }
            })
          }
        })
      }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(5).columnsGap(5)

      // 5. 当日任务列表
      Text(`${this.selectedDate.toLocaleDateString()} 的任务列表`)
        .fontSize(18).fontWeight(500)
        .padding({ top: 20, bottom: 10 })
        .width('100%').textAlign(TextAlign.Start)
        .visibility(this.selectedDateTasks.length > 0 ? Visibility.Visible : Visibility.None)

      List({ space: 8 }) {
        ForEach(this.selectedDateTasks, (task: Task) => {
          ListItem() {
            Row({ space: 12 }) {
              Column().width(5).height(40).backgroundColor(getStatusColor(task.status)).borderRadius(2.5)
              Column() {
                Text(task.taskName).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`${task.executor} | ${task.priority} | ${task.plannedStartTime.split(' ')[1]}`)
                  .fontSize(12).fontColor(Color.Gray)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text(task.status).fontSize(14).fontColor(getStatusColor(task.status))
            }
            .padding(12)
            .alignItems(VerticalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(10)
            // 手动定义一个卡片阴影效果
            .shadow({ radius: 6, color: 'rgba(0,0,0,0.1)', offsetX: 2, offsetY: 2 })
            // 使用 stateStyles 来定义按下时的样式
            .stateStyles({
              pressed: {
                // 定义当组件被按下时，背景颜色会发生变化
                .backgroundColor('#f0f0f0')
              }
            })
            .onClick(() => {
              router.pushUrl({ url: 'pages/TaskDetailPage', params: { task: JSON.stringify(task) } })
            })
          }
        }, (item: Task) => item.id.toString())
      }.layoutWeight(1)

    }
    .width('100%').height('100%')
    .padding(12)
    .backgroundColor('#f0f2f5')
  }
}