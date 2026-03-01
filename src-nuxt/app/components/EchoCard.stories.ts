import type { Meta, StoryObj } from '@storybook/vue3'
import EchoCard from './EchoCard.vue'

const meta = {
  title: 'Components/EchoCard',
  component: EchoCard,
  tags: ['autodocs'],
  argTypes: {
    title: { control: 'text' },
  },
} satisfies Meta<typeof EchoCard>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    invoker: async (message: string) => {
      await new Promise((resolve) => setTimeout(resolve, 500))
      return `Echo: ${message}`
    },
  },
}

export const InstantResponse: Story = {
  args: {
    invoker: async (message: string) => `Echo: ${message}`,
  },
}

export const ErrorState: Story = {
  args: {
    invoker: async () => {
      throw new Error('Connection refused')
    },
  },
}

export const CustomTitle: Story = {
  args: {
    title: 'Send a Message',
    invoker: async (message: string) => `Received: ${message}`,
  },
}
