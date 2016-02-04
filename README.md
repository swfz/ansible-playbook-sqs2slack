# ansible-playbook-sqs2slack
## Case
- cloudwatch -> sns -> sqs -> slack

## requirement
- use aws cli for python in no password
    - registered password in aws config.
    - EC2 has IAM Role.
    - installed jq.

## insntall

### dependency role

```
ansible-galaxy install -r requirements.yml -p roles
```

### provisioning

```
ansible-playbook -i hosts site.yml
```

