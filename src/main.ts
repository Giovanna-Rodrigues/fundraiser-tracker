import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import ConfirmationService from 'primevue/confirmationservice'

// PrimeVue theme
import { definePreset } from '@primevue/themes'
import Aura from '@primevue/themes/aura'

// PrimeVue components
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import Toast from 'primevue/toast'
import Tag from 'primevue/tag'
import Badge from 'primevue/badge'
import Avatar from 'primevue/avatar'
import Chart from 'primevue/chart'
import Divider from 'primevue/divider'

// PrimeIcons
import 'primeicons/primeicons.css'

import App from './App.vue'
import router from './router'

// Define custom theme preset
const MyPreset = definePreset(Aura, {
  semantic: {
    primary: {
      50: '#fef7f0',
      100: '#fdeee0',
      200: '#fad9c0',
      300: '#f7c196',
      400: '#f3a26a',
      500: '#ef7f47',
      600: '#e06324',
      700: '#ba4e1b',
      800: '#943f1c',
      900: '#77351c',
      950: '#40190a'
    }
  }
})

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(PrimeVue, {
  theme: {
    preset: MyPreset,
    options: {
      darkModeSelector: '.app-dark'
    }
  }
})
app.use(ToastService)
app.use(ConfirmationService)

// Register PrimeVue components globally
app.component('Button', Button)
app.component('InputText', InputText)
app.component('InputNumber', InputNumber)
app.component('Dropdown', Dropdown)
app.component('Calendar', Calendar)
app.component('DataTable', DataTable)
app.component('Column', Column)
app.component('Dialog', Dialog)
app.component('Toast', Toast)
app.component('Tag', Tag)
app.component('Badge', Badge)
app.component('Avatar', Avatar)
app.component('Chart', Chart)
app.component('Divider', Divider)

app.mount('#app')
