# Subscriptify: On-chain Subscription Management

Subscriptify is a comprehensive on-chain subscription management system built on Clarity/Stacks blockchain. It enables creators to offer subscription-based products and services while providing users with NFT-based proof of their subscription status.

## Features

- **Flexible Plan Management**: Create, update, and pause subscription plans with customizable periods and pricing.
- **Multi-token Support**: Accept payments in STX or any SIP-010 fungible token.
- **NFT Subscription Passes**: Each subscription mints an NFT representing the user's access rights.
- **Admin Controls**: Platform fees, emergency pause, and other administrative functions.
- **Composable Access Control**: Simple interfaces for other contracts to verify subscription status.

## Architecture

The project is organized into several specialized contracts:

- **plan-manager.clar**: Handles creating and managing subscription plans
- **subscription-manager.clar**: Core subscription logic for subscribing, renewing, and canceling
- **pass-nft.clar**: SIP-009 implementation for subscription pass NFTs
- **access-control.clar**: Read-only views for subscription status verification
- **token-payment.clar**: Abstraction layer for handling different token payments
- **admin.clar**: Platform-wide administrative functions
- **utils/math-time.clar**: Time conversion utilities

## Installation

To set up the project locally:

1. Install Clarinet if not already installed
   ```bash
   curl -sS https://install.clarinet.com | sh