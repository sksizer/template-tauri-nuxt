import type { Meta, StoryObj } from '@storybook/vue3'
import ResultBanner from './ResultBanner.vue'

const meta = {
  title: 'Components/ResultBanner',
  component: ResultBanner,
  tags: ['autodocs'],
  argTypes: {
    message: { control: 'text' },
  },
} satisfies Meta<typeof ResultBanner>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    message: 'Hello from Tauri!',
  },
}

export const LongMessage: Story = {
  args: {
    message: 'This is a much longer message to test how the result banner handles text that extends beyond the typical length. It should wrap gracefully within the container.',
  },
}

export const ErrorMessage: Story = {
  args: {
    message: 'Error: Failed to connect to the Tauri backend. Please ensure the application is running correctly.',
  },
}
