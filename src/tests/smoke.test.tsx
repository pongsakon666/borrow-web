import { render, screen } from '@testing-library/react'
import { QueryClient } from '@tanstack/react-query'
import { AppProviders } from '@/app/providers'

describe('AppProviders', () => {
  it('renders children', () => {
    const client = new QueryClient()
    render(
      <AppProviders client={client}>
        <p>hello</p>
      </AppProviders>,
    )
    expect(screen.getByText('hello')).toBeInTheDocument()
  })
})
