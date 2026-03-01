import type { Meta, StoryObj } from '@storybook/vue3'
import AppHeader from './AppHeader.vue'

const meta = {
  title: 'Components/AppHeader',
  component: AppHeader,
  tags: ['autodocs'],
  argTypes: {
    title: { control: 'text' },
    subtitle: { control: 'text' },
  },
} satisfies Meta<typeof AppHeader>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    title: 'Tauri + Nuxt',
    subtitle: 'Desktop apps with web technologies',
  },
}

export const CustomText: Story = {
  args: {
    title: 'My Custom App',
    subtitle: 'A different subtitle for testing',
  },
}

export const LongText: Story = {
  args: {
    title: 'This Is a Very Long Title That Might Wrap on Smaller Screens',
    subtitle:
      'And this is an equally long subtitle to test how the layout handles extended text content gracefully',
  },
}
