### Diamond Pattern

- The Diamond Standard is a proxy design pattern that enables the modularity and upgradeability of smart contracts
- The Diamond Standard works like other proxy standards; they store the data of the smart contract and use the Solidity "fallback" function to make "delegate calls" to facets that contain the actual logic code
- A smart contract that implements this standard is known as a "Diamond", and the contracts that provide different functionalities to the diamond are known as "Facets"

### Key Features

- Smart contract upgradeability
- Unlimited functionality smart contracts (Facets)
- No smart contract code size limit
- Modular and structural arrangement of code and data
- Developers can add multiple facets to a diamond

### Architecture

- The Diamond - The central contract that acts as a proxy and routes function calls to the appropriate facets. It contains a mapping of function selectors to facet addresses
- Facet - Individual contracts that implement specific functionality. Each facet contains a set of functions that can be called by the diamond
- Loupe - A set of standard functions defined in EIP-2535 that provide information about the facets and function selectors used in the diamond. The diamond loupe allows developers and users to inspect and understand the structure of the diamond
- Diamond Cut - FacetCutAction - function used to add, replace or remove facets and their corresponding function selectors in the diamonds. Only an authorized address (e.g, the diamond's owner or a multi-signature contract) can perform a diamond cut
- The Diamond Storage & App Storage
