// /entry/src/main/ets/pages/LoginPage.ets

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../services/ApiService';
import authService from '../services/AuthService';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State captcha: string = '';
  @State uuid: string = '';
  @State captchaImage: string = '';
  @State isLoading: boolean = false;

  async aboutToAppear() {
    await this.refreshCaptcha();
  }

  async refreshCaptcha() {
    this.captchaImage = '';
    try {
      const res = await ApiService.getCaptcha();
      this.uuid = res.uuid;
      this.captchaImage = res.img;
    } catch (e) {
      // 修正：使用 instanceof 进行类型检查
      let errorMessage = '未知错误';
      if (e instanceof Error) {
        errorMessage = e.message;
      } else {
        errorMessage = JSON.stringify(e);
      }
      promptAction.showToast({ message: `验证码加载失败: ${errorMessage}` });
      console.error(`Failed to refresh captcha: ${errorMessage}`);
    }
  }

  async handleLogin() {
    if (!this.username || !this.password || !this.captcha) {
      promptAction.showToast({ message: '请填写所有登录项' });
      return;
    }
    this.isLoading = true;
    try {
      const res = await ApiService.login({
        username: this.username,
        password: this.password,
        captcha: this.captcha,
        uuid: this.uuid
      });
      authService.setToken(res.token);
      promptAction.showToast({ message: '登录成功！' });
      router.replaceUrl({ url: 'pages/DefectListPage' });

    } catch (e) {
      // 修正：使用 instanceof 进行类型检查
      let errorMessage = '未知错误';
      if (e instanceof Error) {
        errorMessage = e.message;
      } else {
        errorMessage = JSON.stringify(e);
      }
      promptAction.showToast({ message: `登录失败: ${errorMessage}` });
      await this.refreshCaptcha();
    } finally {
      this.isLoading = false;
    }
  }


  build() {
    Column() {
      Text('地铁隧道巡检平台')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      TextInput({ placeholder: '请输入账号' })
        .onChange(val => this.username = val)
        .width('80%').margin({ bottom: 15 })

      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .onChange(val => this.password = val)
        .width('80%').margin({ bottom: 15 })

      Row({ space: 10 }) {
        TextInput({ placeholder: '请输入验证码' })
          .onChange(val => this.captcha = val)
          .layoutWeight(1)

        Stack({ alignContent: Alignment.Center }) {
          Image(this.captchaImage)
            .border({ width: 1, color: '#e0e0e0', radius: 4 })

          if(!this.captchaImage) {
            Text('加载中...').fontColor(Color.Gray)
          }
        }
        .width(120).height(40)
        .onClick(() => this.refreshCaptcha())

      }
      .width('80%')
      .margin({ bottom: 30 })
      .alignItems(VerticalAlign.Center)


      Button('登 录', { type: ButtonType.Capsule })
        .width('80%').height(45)
        .fontSize(18)
        .stateEffect(true)
        .backgroundColor(this.isLoading ? '#a0cfff' : '#409eff')
        .enabled(!this.isLoading)
        .onClick(() => this.handleLogin())
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }
}