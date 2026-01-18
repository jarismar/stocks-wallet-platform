# Stocks Wallet Database Module

We keep the database diagram in MySQLWorkbench.

## DB engine

This is a MySQL server 8.0+

## Table prefixes

Use these table prefixes as a standard for all sql join stmts.

| Table               | Prefix |
| ------------------- | ------ |
| asset               | ast    |
| asset_class         | acs    |
| broker_invoice      | biv    |
| broker_invoice_item | bii    |
| permission          | perm   |
| role                | role   |
| role_perm           | rpm    |
| tax_instance        | tin    |
| tax_group           | tgr    |
| user                | usr    |
| user_role           | uro    |

## Enumerations

**Roles**

| ID | Code   | Desc |
| -- | ------ | ---- |
|  1 | ADMIN  |      |
|  2 | USER   |      | 

**Asset Classes**

| Id | Code    | Desc        |
| -- | ------- | ----------- |
|  1 | STOCK   | Stock       |
|  2 | STOCKUN | Stock units |

## TODO

- Next tables
  - asset_oplog
  - asset_balance
