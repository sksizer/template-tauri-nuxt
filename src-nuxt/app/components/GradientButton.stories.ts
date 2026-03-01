import type { Meta, StoryObj } from '@storybook/vue3'
import { fn } from '@storybook/test'
import GradientButton from './GradientButton.vue'

const meta = {
  title: 'Components/GradientButton',
  component: GradientButton,
  tags: ['autodocs'],
  argTypes: {
    label: { control: 'text' },
    type: { control: 'select', options: ['button', 'submit'] },
  },
} satisfies Meta<typeof GradientButton>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    label: 'Echo',
  },
}

export const CustomLabel: Story = {
  args: {
    label: 'Send Message',
  },
}

export const WithClickAction: Story = {
  args: {
    label: 'Click Me',
    onClick: fn(),
  },
}
