## Impact Network

A decentralized smart contract system for tracking academic papers, citations, and scholarly impact on the Stacks blockchain.

## Overview

The Scholarly Impact Network is a blockchain-based platform that enables researchers to:
- Submit and register academic papers
- Create verifiable citation networks
- Track scholarly impact metrics
- Earn rewards for research contributions
- Participate in decentralized peer review

## Features

### 📄 Paper Submission
- Register academic papers with metadata (title, abstract, field of study)
- Immutable timestamping and authorship verification
- Support for multiple research fields

### 🔗 Citation Network
- Create verifiable citations between papers
- Track citation context and relevance scores
- Prevent self-citation abuse
- Build transparent academic networks

### 📊 Impact Metrics
- Automatic citation counting
- Scholar profile tracking
- H-index calculation
- Field-specific analytics

### 🏆 Reward System
- Earn reward points for paper citations
- Bonus points for peer-reviewed papers
- Claimable reward tokens
- Incentivized scholarly participation

### 👥 Peer Review
- Decentralized peer review system
- Authorized reviewer network
- Verification of paper quality
- Enhanced credibility scoring

## Smart Contract Functions

### Public Functions

#### Paper Management
- `submit-paper` - Register a new academic paper
- `peer-review-paper` - Mark a paper as peer-reviewed

#### Citation Network
- `add-citation` - Create a citation link between papers
- `get-citation-info` - Retrieve citation details

#### Rewards & Profiles
- `claim-reward-points` - Claim accumulated reward points
- `get-scholar-profile` - View scholar statistics
- `calculate-h-index` - Calculate scholarly H-index

#### Administration
- `authorize-peer-reviewer` - Add authorized reviewers
- `revoke-peer-reviewer` - Remove reviewer authorization

### Read-Only Functions

#### Query Functions
- `get-paper-info` - Retrieve paper details
- `get-paper-citations` - Get citation count for a paper
- `get-field-stats` - View field-specific statistics
- `get-scholar-rewards` - Check reward point balance
- `is-authorized-reviewer` - Verify reviewer status

## Data Structures

### Academic Papers
```clarity
{
  title: string-ascii,
  author: principal,
  submission-time: uint,
  field-of-study: string-ascii,
  abstract: string-utf8,
  is-peer-reviewed: bool
}
```

### Citation Network
```clarity
{
  citation-time: uint,
  citation-context: optional string-utf8,
  relevance-score: uint
}
```

### Scholar Profiles
```clarity
{
  paper-count: uint,
  total-citations: uint,
  impact-score: uint
}
```

## Usage Examples

### Submitting a Paper
```clarity
(submit-paper 
  "paper-001" 
  "Blockchain-Based Academic Networks" 
  "Computer Science" 
  "This paper explores decentralized academic publishing...")
```

### Adding a Citation
```clarity
(add-citation 
  "my-paper-001" 
  "cited-paper-002" 
  (some "This work builds upon the foundational research...") 
  u8)
```

### Claiming Rewards
```clarity
(claim-reward-points)
```

## Error Codes

- `ERR_ACCESS_DENIED` (u200) - Unauthorized access attempt
- `ERR_ALREADY_EXISTS` (u201) - Resource already exists
- `ERR_NOT_FOUND` (u202) - Resource not found
- `ERR_INVALID_CITATION` (u203) - Invalid citation attempt
- `ERR_INVALID_INPUT` (u204) - Invalid input parameters
- `ERR_MALFORMED_REQUEST` (u205) - Malformed request data

## Getting Started

1. **Deploy the Contract**: Deploy the smart contract to the Stacks blockchain
2. **Submit Papers**: Register your academic papers using `submit-paper`
3. **Build Citations**: Create citation networks with `add-citation`
4. **Earn Rewards**: Accumulate reward points through citations and peer review
5. **Track Impact**: Monitor your scholarly impact through profile queries

## Security Features

- **Authorship Verification**: Papers are tied to submitting principal
- **Citation Validation**: Prevents self-citations and validates paper existence
- **Access Control**: Admin-only functions for reviewer management
- **Input Validation**: Comprehensive input sanitization and validation

## Future Enhancements

- Integration with IPFS for paper storage
- Multi-signature peer review processes
- Cross-chain citation networks
- Advanced analytics and visualization tools
- Token-based governance mechanisms

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.