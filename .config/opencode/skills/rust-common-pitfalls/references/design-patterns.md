<!-- This file is loaded on demand from the main SKILL.md Deep Dives section -->

### Pattern 2: Builder Pattern with Validation

```rust
pub struct UserBuilder {
    name: Option<String>,
    email: Option<String>,
    age: Option<u8>,
}

impl UserBuilder {
    pub fn new() -> Self {
        Self {
            name: None,
            email: None,
            age: None,
        }
    }

    pub fn name(mut self, name: impl Into<String>) -> Self {
        self.name = Some(name.into());
        self
    }

    pub fn email(mut self, email: impl Into<String>) -> Self {
        self.email = Some(email.into());
        self
    }

    pub fn age(mut self, age: u8) -> Self {
        self.age = Some(age);
        self
    }

    /// Builds the User, performing validation.
    /// # Errors
    /// Returns UserError if required fields are missing or invalid.
    pub fn build(self) -> Result<User, UserError> {
        let name = self.name.ok_or(UserError::MissingField("name"))?;
        let email = self.email.ok_or(UserError::MissingField("email"))?;
        let age = self.age.unwrap_or(0);  // default

        User::new(name, email, age)
    }
}

impl Default for UserBuilder {
    fn default() -> Self {
        Self::new()
    }
}

// Usage
let user = UserBuilder::new()
    .name("Alice")
    .email("alice@example.com")
    .age(30)
    .build()
    .expect("valid input");
```

### Pattern 3: Factory Pattern for Multiple Variants

```rust
pub struct VulnerabilityFinding {
    id: String,
    severity: Severity,
    message: String,
    location: Location,
    // ... many more fields
}

pub enum Severity {
    Info,
    Low,
    Medium,
    High,
    Critical,
}

impl VulnerabilityFinding {
    /// Factory for SQL injection findings
    pub fn sql_injection(location: Location, query: &str) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            severity: Severity::High,
            message: format!("Potential SQL injection in: {}", query),
            location,
            // ... set other fields appropriately
        }
    }

    /// Factory for hardcoded credentials
    pub fn hardcoded_credential(location: Location, credential_type: &str) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            severity: Severity::Critical,
            message: format!("Hardcoded {} detected", credential_type),
            location,
            // ...
        }
    }
}
```

### Pattern 4: Newtype for Type Safety

```rust
/// Newtype wrapper to prevent mixing up UserId and OrderId
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct UserId(pub u64);

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct OrderId(pub u64);

impl UserId {
    pub fn new(id: u64) -> Self {
        Self(id)
    }
}

impl OrderId {
    pub fn new(id: u64) -> Self {
        Self(id)
    }
}

// This prevents accidental argument swapping
fn get_user_orders(user_id: UserId, order_id: OrderId) -> Result<Order, ()> {
    // Cannot accidentally swap - type system catches it
    todo!()
}

// Usage
let user_id = UserId::new(42);
let order_id = OrderId::new(1);
get_user_orders(user_id, order_id).ok();
```