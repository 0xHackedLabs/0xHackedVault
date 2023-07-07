# 0xHacked Vault

## Design

```mermaid
sequenceDiagram
    participant whitehat
    participant project
    participant 0xHacked Vault
    participant 0xHacked zkVerifier
    whitehat->>0xHacked zkVerifier: Proof of exploit
    0xHacked zkVerifier->>0xHacked Vault: create a new case with whitehat's receiver address
    project->>0xHacked Vault: Send the bounty to the 0xHacked Vault
    whitehat->>project: original PoC
    loop FixTheExp
        whitehat->>project: co-fix the exploit
    end
    project->>0xHacked Vault: Confirm the bounty payment
    0xHacked Vault->>whitehat: Send the bounty to the whitehat, 0xHacked Vault will take a commission
```

If the whitehat doesn’t provide the PoC or the PoC doesn’t work after the project sends the bounty to the Vault, the reward will be locked in the 0xHacked Vault. Also, if the project doesn’t confirm the payment after fixing the exploit, they can’t get the deposit back guaranteed by our smart contract.
