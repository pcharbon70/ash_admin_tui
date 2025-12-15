# Phase 3: Authentication & Ash Integration

## Phase Overview

Phase 3 integrates AshAuthentication for secure access and connects the UI to real Ash resources. This phase transforms the TUI from a mock interface into a functional admin tool that enforces policies and respects multi-tenancy.

The implementation adds authentication on startup, resource discovery through Ash introspection, and proper actor/tenant context management for all operations. By replacing mock data with real Ash queries and mutations, the TUI becomes a complete admin interface with full CRUD capabilities.

By the end of Phase 3, users will authenticate with valid credentials, browse real Ash resources with policy enforcement, perform CRUD operations that respect authorization rules, impersonate other users to test policies, and switch tenants in multi-tenant applications. All operations will honor Ash policies and multi-tenancy constraints.

## 3.1 Authentication System

- [ ] **Section 3.1 Complete**

The authentication system validates admin credentials using AshAuthentication and manages session state including JWT tokens and user context. This ensures only authorized users can access the TUI and provides the foundation for actor-based policy enforcement.

### 3.1.1 Implement Authentication Module

- [ ] **Task 3.1.1 Complete**

Create authentication service that handles login, token storage, and session management. This module integrates with AshAuthentication to validate credentials and maintain authenticated session state.

- [ ] 3.1.1.1 Create lib/ash_admin_tui/auth/session.ex module
- [ ] 3.1.1.2 Define session state: `%{authenticated_user: %{}, jwt_token: nil, expires_at: nil, refresh_token: nil}`
- [ ] 3.1.1.3 Implement authenticate/2 function taking email and password
- [ ] 3.1.1.4 Call AshAuthentication sign-in endpoint with credentials
- [ ] 3.1.1.5 Store JWT token and expiration in state on success
- [ ] 3.1.1.6 Implement get_current_user/0 returning authenticated user
- [ ] 3.1.1.7 Implement logout/0 clearing tokens and session state

### 3.1.2 Implement Login UI

- [ ] **Task 3.1.2 Complete**

Build login screen with email/password form and error handling. This provides the initial interface users see before accessing the main TUI.

- [ ] 3.1.2.1 Create login view component in lib/ash_admin_tui/views/login_view.ex
- [ ] 3.1.2.2 Render form with email and password input fields
- [ ] 3.1.2.3 Mask password input using TermUI password mode or :io.setopts echo: false
- [ ] 3.1.2.4 Handle Enter key to submit credentials
- [ ] 3.1.2.5 Display loading spinner during authentication
- [ ] 3.1.2.6 On success: transition to main UI
- [ ] 3.1.2.7 On failure: display error message and allow retry

### 3.1.3 Implement Authorization Check

- [ ] **Task 3.1.3 Complete**

Verify authenticated user has admin role/permission to access the TUI. This prevents non-admin users from accessing the interface even if they have valid credentials.

- [ ] 3.1.3.1 Implement check_admin_role/1 function taking authenticated user
- [ ] 3.1.3.2 Read admin role requirement from config (:admin by default)
- [ ] 3.1.3.3 Check user's role or permissions against requirement
- [ ] 3.1.3.4 Return {:ok, user} if authorized
- [ ] 3.1.3.5 Return {:error, :unauthorized} if not authorized
- [ ] 3.1.3.6 Display "Access Denied" message and exit if unauthorized

### 3.1.4 Unit Tests - Section 3.1

- [ ] **Unit Tests 3.1 Complete**

- [ ] Test authenticate/2 succeeds with valid credentials
- [ ] Test authenticate/2 fails with invalid credentials
- [ ] Test authenticate/2 stores JWT token on success
- [ ] Test get_current_user/0 returns authenticated user
- [ ] Test logout/0 clears session state
- [ ] Test check_admin_role/1 accepts user with admin role
- [ ] Test check_admin_role/1 rejects user without admin role
- [ ] Test login view renders email and password fields
- [ ] Test login view masks password input
- [ ] Test login view displays errors on auth failure

## 3.2 Resource Discovery

- [ ] **Section 3.2 Complete**

Resource discovery introspects Ash domains and resources to build the navigation structure and metadata cache used throughout the TUI. This replaces the mock domain/resource structure from Phase 2 with real Ash configuration.

### 3.2.1 Implement Domain Enumeration

- [ ] **Task 3.2.1 Complete**

Build service to discover and filter domains marked for admin display. This identifies which Ash domains should appear in the TUI navigation.

- [ ] 3.2.1.1 Create lib/ash_admin_tui/ash/resource_discovery.ex module
- [ ] 3.2.1.2 Implement load_domains/0 function
- [ ] 3.2.1.3 Get all domains from Application.get_env(:ash_admin, :domains)
- [ ] 3.2.1.4 Filter domains with AshAdmin.Domain extension
- [ ] 3.2.1.5 Filter domains where AshAdmin.Domain.show? is true
- [ ] 3.2.1.6 Return list of domain modules

### 3.2.2 Implement Resource Introspection

- [ ] **Task 3.2.2 Complete**

Build introspection functions to extract resource metadata using Ash reflection APIs. This gathers all necessary information about resources for rendering forms, lists, and detail views.

- [ ] 3.2.2.1 Implement load_resources/1 taking domain module
- [ ] 3.2.2.2 Call Ash.Domain.Info.resources/1 to get resource list
- [ ] 3.2.2.3 For each resource, call Ash.Resource.Info.public_attributes/1
- [ ] 3.2.2.4 For each resource, call Ash.Resource.Info.public_relationships/1
- [ ] 3.2.2.5 For each resource, call Ash.Resource.Info.actions/1
- [ ] 3.2.2.6 For each resource, call Ash.Resource.Info.primary_key/1
- [ ] 3.2.2.7 Check AshAdmin.Resource.actor? to identify actor resources

### 3.2.3 Implement Metadata Caching

- [ ] **Task 3.2.3 Complete**

Build caching layer to store resource metadata and avoid repeated introspection. This improves performance by loading metadata once at startup.

- [ ] 3.2.3.1 Create GenServer for metadata cache
- [ ] 3.2.3.2 On init, call load_domains/0 and load_resources/1 for each domain
- [ ] 3.2.3.3 Store metadata in ETS table for fast lookup
- [ ] 3.2.3.4 Implement get_resource/1 retrieving resource metadata by name
- [ ] 3.2.3.5 Implement get_domains/0 returning all domains with resources
- [ ] 3.2.3.6 Implement refresh/0 to reload metadata (for development)

### 3.2.4 Unit Tests - Section 3.2

- [ ] **Unit Tests 3.2 Complete**

- [ ] Test load_domains/0 returns only domains with show? true
- [ ] Test load_resources/1 returns all resources for domain
- [ ] Test resource metadata includes attributes
- [ ] Test resource metadata includes relationships
- [ ] Test resource metadata includes actions
- [ ] Test resource metadata includes primary key
- [ ] Test actor? flag correctly identified
- [ ] Test metadata cache stores and retrieves correctly
- [ ] Test get_resource/1 returns cached metadata
- [ ] Test refresh/0 reloads metadata

## 3.3 Actor Context Management

- [ ] **Section 3.3 Complete**

Actor context management tracks the current actor for all Ash operations and supports impersonation for testing policies. This enables administrators to view and interact with resources as other users would see them.

### 3.3.1 Implement Actor Manager

- [ ] **Task 3.3.1 Complete**

Create actor context manager with impersonation support. This maintains the current actor context used for all Ash operations and allows switching between authenticated user and impersonated user.

- [ ] 3.3.1.1 Create lib/ash_admin_tui/context/actor_manager.ex module
- [ ] 3.3.1.2 Define state: `%{authenticated_user: %{}, current_actor: %{}, impersonating: false}`
- [ ] 3.3.1.3 Implement init/1 setting both users to authenticated user
- [ ] 3.3.1.4 Implement get_current_actor/0 returning actor for Ash operations
- [ ] 3.3.1.5 Implement start_impersonation/1 taking target user
- [ ] 3.3.1.6 Implement end_impersonation/0 reverting to authenticated user
- [ ] 3.3.1.7 Implement is_impersonating?/0 returning boolean

### 3.3.2 Implement Actor Switcher UI

- [ ] **Task 3.3.2 Complete**

Build impersonation dialog with user search and selection. This provides the UI for administrators to choose which user to impersonate.

- [ ] 3.3.2.1 Create actor switcher dialog component
- [ ] 3.3.2.2 Use PickList widget with searchable user list
- [ ] 3.3.2.3 Query actor resource for available users
- [ ] 3.3.2.4 Implement type-ahead filtering by name or email
- [ ] 3.3.2.5 On selection, call start_impersonation/1
- [ ] 3.3.2.6 Update top bar to show impersonation status in yellow
- [ ] 3.3.2.7 Add "Return to Self" shortcut (Shift-I) to exit impersonation

### 3.3.3 Implement Authorization for Impersonation

- [ ] **Task 3.3.3 Complete**

Add permission check that only allows authorized users to impersonate. This prevents unauthorized access to the impersonation feature.

- [ ] 3.3.3.1 Implement can_impersonate?/1 function
- [ ] 3.3.3.2 Check if user has impersonation permission or admin role
- [ ] 3.3.3.3 Hide impersonation UI if user cannot impersonate
- [ ] 3.3.3.4 Return error if unauthorized user attempts impersonation

### 3.3.4 Unit Tests - Section 3.3

- [ ] **Unit Tests 3.3 Complete**

- [ ] Test actor manager initializes with authenticated user
- [ ] Test get_current_actor/0 returns authenticated user initially
- [ ] Test start_impersonation/1 switches current actor
- [ ] Test get_current_actor/0 returns impersonated user
- [ ] Test is_impersonating?/0 returns true when impersonating
- [ ] Test end_impersonation/0 reverts to authenticated user
- [ ] Test can_impersonate?/1 allows admin users
- [ ] Test can_impersonate?/1 denies non-admin users

## 3.4 Tenant Context Management

- [ ] **Section 3.4 Complete**

Tenant context management supports multi-tenancy by tracking the current tenant and applying it to all Ash operations. This enables administrators to work with resources in different tenant contexts.

### 3.4.1 Implement Tenant Manager

- [ ] **Task 3.4.1 Complete**

Create tenant context manager for multi-tenancy support. This maintains the current tenant context used for all Ash operations.

- [ ] 3.4.1.1 Create lib/ash_admin_tui/context/tenant_manager.ex module
- [ ] 3.4.1.2 Define state: `%{current_tenant: nil, available_tenants: []}`
- [ ] 3.4.1.3 Implement init/1 with default tenant from config
- [ ] 3.4.1.4 Implement get_current_tenant/0 returning tenant for Ash operations
- [ ] 3.4.1.5 Implement set_tenant/1 changing current tenant
- [ ] 3.4.1.6 Implement load_tenants/0 querying available tenants

### 3.4.2 Implement Tenant Switcher UI

- [ ] **Task 3.4.2 Complete**

Build tenant switching dialog with tenant selection. This provides the UI for switching between different tenant contexts.

- [ ] 3.4.2.1 Create tenant switcher dialog component
- [ ] 3.4.2.2 Display list of available tenants or text input for tenant ID
- [ ] 3.4.2.3 On selection, call set_tenant/1
- [ ] 3.4.2.4 Reload current view with new tenant context
- [ ] 3.4.2.5 Update top bar to show current tenant
- [ ] 3.4.2.6 Apply blue/info color to tenant indicator

### 3.4.3 Unit Tests - Section 3.4

- [ ] **Unit Tests 3.4 Complete**

- [ ] Test tenant manager initializes with default tenant
- [ ] Test get_current_tenant/0 returns current tenant
- [ ] Test set_tenant/1 updates current tenant
- [ ] Test load_tenants/0 returns available tenants
- [ ] Test tenant switcher displays tenant list
- [ ] Test tenant switcher updates context on selection
- [ ] Test top bar displays current tenant

## 3.5 Ash Query Service

- [ ] **Section 3.5 Complete**

The query service executes Ash read operations with proper actor/tenant context, replacing mock data with real queries. This provides the data layer for all list and detail views.

### 3.5.1 Implement Query Service

- [ ] **Task 3.5.1 Complete**

Create query service for listing and fetching records with context injection. This builds Ash queries with proper actor and tenant context.

- [ ] 3.5.1.1 Create lib/ash_admin_tui/ash/query_service.ex module
- [ ] 3.5.1.2 Implement list_records/2 taking resource and options
- [ ] 3.5.1.3 Build Ash.Query.for_read with :read action
- [ ] 3.5.1.4 Inject actor from ActorManager.get_current_actor/0
- [ ] 3.5.1.5 Inject tenant from TenantManager.get_current_tenant/0
- [ ] 3.5.1.6 Apply pagination with limit and offset
- [ ] 3.5.1.7 Execute query with Ash.read/1 and return results

### 3.5.2 Implement Sorting and Filtering

- [ ] **Task 3.5.2 Complete**

Add sorting and filtering support to query service. This enables list views to sort by columns and apply filters.

- [ ] 3.5.2.1 Implement apply_sort/3 adding Ash.Query.sort to query
- [ ] 3.5.2.2 Implement apply_filter/2 adding Ash.Query.filter to query
- [ ] 3.5.2.3 Accept sort parameters in list_records options
- [ ] 3.5.2.4 Accept filter parameters in list_records options
- [ ] 3.5.2.5 Apply sorts before pagination
- [ ] 3.5.2.6 Apply filters before pagination

### 3.5.3 Implement Single Record Fetch

- [ ] **Task 3.5.3 Complete**

Add function to fetch single record by primary key. This provides the data for detail views.

- [ ] 3.5.3.1 Implement get_record/2 taking resource and ID
- [ ] 3.5.3.2 Build Ash.Query.for_read with :read action
- [ ] 3.5.3.3 Add filter for primary key matching ID
- [ ] 3.5.3.4 Inject actor and tenant context
- [ ] 3.5.3.5 Execute with Ash.read_one/1
- [ ] 3.5.3.6 Return {:ok, record} or {:error, :not_found}

### 3.5.4 Unit Tests - Section 3.5

- [ ] **Unit Tests 3.5 Complete**

- [ ] Test list_records/2 builds correct Ash query
- [ ] Test list_records/2 injects actor context
- [ ] Test list_records/2 injects tenant context when present
- [ ] Test list_records/2 applies pagination
- [ ] Test apply_sort/3 adds sort to query
- [ ] Test apply_filter/2 adds filter to query
- [ ] Test get_record/2 fetches single record by ID
- [ ] Test get_record/2 returns error when not found
- [ ] Test authorization errors are caught and returned

## 3.6 Ash Mutation Service

- [ ] **Section 3.6 Complete**

The mutation service handles create, update, and destroy operations with proper validation and error handling. This provides the data layer for form submissions and delete operations.

### 3.6.1 Implement Create Operation

- [ ] **Task 3.6.1 Complete**

Build create functionality using Ash changesets. This enables creating new records through the form view.

- [ ] 3.6.1.1 Create lib/ash_admin_tui/ash/mutation_service.ex module
- [ ] 3.6.1.2 Implement create_record/2 taking resource and attributes
- [ ] 3.6.1.3 Build Ash.Changeset.for_create with :create action
- [ ] 3.6.1.4 Inject actor and tenant context
- [ ] 3.6.1.5 Execute with Ash.create/1
- [ ] 3.6.1.6 Return {:ok, record} on success
- [ ] 3.6.1.7 Return {:error, changeset} on validation failure

### 3.6.2 Implement Update Operation

- [ ] **Task 3.6.2 Complete**

Build update functionality with changeset validation. This enables editing existing records through the form view.

- [ ] 3.6.2.1 Implement update_record/3 taking resource, record, and attributes
- [ ] 3.6.2.2 Build Ash.Changeset.for_update with :update action
- [ ] 3.6.2.3 Inject actor and tenant context
- [ ] 3.6.2.4 Execute with Ash.update/1
- [ ] 3.6.2.5 Return {:ok, record} on success
- [ ] 3.6.2.6 Return {:error, changeset} on validation failure

### 3.6.3 Implement Destroy Operation

- [ ] **Task 3.6.3 Complete**

Build delete functionality with authorization checks. This enables deleting records from list or detail views.

- [ ] 3.6.3.1 Implement delete_record/2 taking resource and record
- [ ] 3.6.3.2 Build Ash.Changeset.for_destroy with :destroy action
- [ ] 3.6.3.3 Inject actor and tenant context
- [ ] 3.6.3.4 Execute with Ash.destroy/1
- [ ] 3.6.3.5 Return :ok on success
- [ ] 3.6.3.6 Return {:error, reason} on failure

### 3.6.4 Implement Error Handling

- [ ] **Task 3.6.4 Complete**

Add comprehensive error handling for all mutation types. This ensures validation and authorization errors are properly formatted for display in the UI.

- [ ] 3.6.4.1 Implement extract_validation_errors/1 for changeset errors
- [ ] 3.6.4.2 Implement format_error/1 for authorization errors
- [ ] 3.6.4.3 Handle Ash.Error.Forbidden errors separately
- [ ] 3.6.4.4 Handle Ash.Error.Invalid errors with field details
- [ ] 3.6.4.5 Return user-friendly error messages
- [ ] 3.6.4.6 Log detailed errors for debugging

### 3.6.5 Unit Tests - Section 3.6

- [ ] **Unit Tests 3.6 Complete**

- [ ] Test create_record/2 creates record with valid data
- [ ] Test create_record/2 returns validation errors for invalid data
- [ ] Test create_record/2 injects actor context
- [ ] Test update_record/3 updates record successfully
- [ ] Test update_record/3 returns validation errors
- [ ] Test delete_record/2 deletes record
- [ ] Test operations fail when actor lacks authorization
- [ ] Test extract_validation_errors/1 formats errors correctly
- [ ] Test format_error/1 creates user-friendly messages

## 3.7 UI Integration with Real Data

- [ ] **Section 3.7 Complete**

Replace mock data in UI components with real Ash queries and mutations. This connects all Phase 2 UI components to the Ash data layer created in this phase.

### 3.7.1 Update List View for Real Data

- [ ] **Task 3.7.1 Complete**

Modify list view to use QueryService instead of mock data. This enables browsing real records from Ash resources.

- [ ] 3.7.1.1 Update ListView.init/1 to call QueryService.list_records/2
- [ ] 3.7.1.2 Remove mock data generation
- [ ] 3.7.1.3 Handle loading state while fetching records
- [ ] 3.7.1.4 Display errors from query failures
- [ ] 3.7.1.5 Pass sort parameters to query service
- [ ] 3.7.1.6 Implement refresh/0 to reload data

### 3.7.2 Update Detail View for Real Data

- [ ] **Task 3.7.2 Complete**

Modify detail view to fetch real record data. This enables viewing full record details from Ash resources.

- [ ] 3.7.2.1 Update DetailView.init/2 to call QueryService.get_record/2
- [ ] 3.7.2.2 Remove mock record data
- [ ] 3.7.2.3 Handle loading state during fetch
- [ ] 3.7.2.4 Display error if record not found
- [ ] 3.7.2.5 Format fields based on real attribute types

### 3.7.3 Update Form View for Real Operations

- [ ] **Task 3.7.3 Complete**

Connect form submissions to real create/update operations. This enables creating and editing records in Ash resources.

- [ ] 3.7.3.1 Update form submit handler to call MutationService.create_record/2
- [ ] 3.7.3.2 Update form submit handler to call MutationService.update_record/3
- [ ] 3.7.3.3 Display validation errors from changeset
- [ ] 3.7.3.4 Show success toast on successful operation
- [ ] 3.7.3.5 Navigate to detail view after create
- [ ] 3.7.3.6 Return to previous view after update

### 3.7.4 Implement Delete Confirmation

- [ ] **Task 3.7.4 Complete**

Add delete confirmation dialog with real destroy operation. This provides a safe way to delete records with confirmation.

- [ ] 3.7.4.1 Create delete confirmation dialog component
- [ ] 3.7.4.2 Display AlertDialog when 'd' pressed in list or detail view
- [ ] 3.7.4.3 Show "Are you sure?" message with resource name
- [ ] 3.7.4.4 On confirm, call MutationService.delete_record/2
- [ ] 3.7.4.5 Show success toast and refresh list on success
- [ ] 3.7.4.6 Show error dialog on failure
- [ ] 3.7.4.7 Close dialog on cancel

### 3.7.5 Unit Tests - Section 3.7

- [ ] **Unit Tests 3.7 Complete**

- [ ] Test ListView fetches real data on init
- [ ] Test ListView displays loading state during fetch
- [ ] Test ListView shows error on query failure
- [ ] Test DetailView fetches real record
- [ ] Test DetailView shows not found error appropriately
- [ ] Test FormView calls create on submit in create mode
- [ ] Test FormView calls update on submit in edit mode
- [ ] Test FormView displays validation errors
- [ ] Test delete confirmation dialog appears
- [ ] Test delete executes on confirmation
- [ ] Test delete cancels on cancel

## 3.8 Integration Tests

- [ ] **Section 3.8 Complete**

Integration tests validate the complete authentication and data flow with real Ash operations. These tests ensure all Phase 3 components work together correctly from login through CRUD operations.

### 3.8.1 Full Authentication Flow

- [ ] **Task 3.8.1 Complete**

Test complete authentication from login to resource display.

- [ ] Test TUI starts with login screen
- [ ] Test entering valid credentials authenticates user
- [ ] Test JWT token is stored in session
- [ ] Test admin role check passes for admin user
- [ ] Test admin role check fails for non-admin user
- [ ] Test navigation loads after successful auth
- [ ] Test resource list displays real domains and resources

### 3.8.2 CRUD Operations with Policies

- [ ] **Task 3.8.2 Complete**

Validate complete CRUD cycle with policy enforcement.

- [ ] Test admin user can create record
- [ ] Test created record appears in list
- [ ] Test admin user can update record
- [ ] Test admin user can delete record
- [ ] Test non-admin user sees authorization errors
- [ ] Test policies filter list view to permitted records
- [ ] Test validation errors display correctly

### 3.8.3 Actor Impersonation Workflow

- [ ] **Task 3.8.3 Complete**

Test full impersonation feature with policy changes.

- [ ] Test admin can open impersonation dialog
- [ ] Test admin can select user from list
- [ ] Test current actor switches to selected user
- [ ] Test list view shows data as impersonated user would see
- [ ] Test impersonated user's policies are enforced
- [ ] Test exiting impersonation reverts to admin
- [ ] Test non-admin cannot access impersonation

### 3.8.4 Multi-Tenant Data Isolation

- [ ] **Task 3.8.4 Complete**

Validate tenant switching and data isolation.

- [ ] Test admin can switch tenant
- [ ] Test list view shows only current tenant's data
- [ ] Test creating record assigns it to current tenant
- [ ] Test switching tenant shows different data
- [ ] Test tenant context is enforced in queries
- [ ] Test cross-tenant access fails appropriately

## Phase 3 Success Criteria

Phase 3 is complete when all of the following criteria are met:

1. **Authentication Works**: Users must log in with valid credentials to access TUI
2. **Authorization Enforced**: Only admin users can access the interface
3. **Real Data**: All views display actual Ash resource data, not mocks
4. **CRUD Functional**: Create, read, update, delete operations work with validation
5. **Policies Respected**: All Ash policies are enforced; unauthorized operations fail
6. **Impersonation Works**: Admins can impersonate users to test policies
7. **Multi-Tenancy**: Tenant switching works if application uses multi-tenancy
8. **Tests Pass**: All unit and integration tests pass
9. **Error Handling**: Validation and authorization errors display properly
10. **Session Management**: JWT tokens are stored and refreshed appropriately

## Provides Foundation For

Phase 3 completes the core functionality of ash_admin_tui, transforming it from a UI prototype into a fully functional admin interface. This provides the foundation for:

- **Phase 4**: Advanced features (custom actions, bulk operations, relationship management)
- **Phase 5**: Polish and optimization (themes, performance tuning, keyboard shortcuts customization)
- **Phase 6**: Production readiness (comprehensive error handling, logging, monitoring, escript packaging)

The authentication, authorization, and Ash integration created in Phase 3 ensures all future features will operate within a secure, policy-enforced environment that respects multi-tenancy and user permissions.
