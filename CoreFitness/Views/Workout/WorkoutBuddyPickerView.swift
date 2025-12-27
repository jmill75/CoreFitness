import SwiftUI
import Contacts

struct WorkoutBuddyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let onSelect: (SelectedWorkoutBuddy) -> Void

    @State private var contacts: [CNContact] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var permissionDenied = false
    @State private var selectedContact: CNContact?
    @State private var selectedPhoneIndex: Int = 0

    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
            return fullName.contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if permissionDenied {
                    permissionDeniedView
                } else if contacts.isEmpty {
                    emptyView
                } else {
                    contactsList
                }
            }
            .navigationTitle("Choose Workout Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
        }
        .task {
            await loadContacts()
        }
        .sheet(item: Binding(
            get: { selectedContact.map { ContactWrapper(contact: $0) } },
            set: { selectedContact = $0?.contact }
        )) { wrapper in
            PhoneNumberPickerSheet(
                contact: wrapper.contact,
                onSelect: { phone in
                    selectBuddy(contact: wrapper.contact, phoneNumber: phone)
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading contacts...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Permission Denied View
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Contacts Access Required")
                .font(.headline)

            Text("To invite a workout buddy, please allow access to your contacts in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Contacts Found")
                .font(.headline)

            Text("Add contacts to your phone to invite workout buddies.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Contacts List
    private var contactsList: some View {
        List(filteredContacts, id: \.identifier) { contact in
            BuddyContactRow(contact: contact)
                .contentShape(Rectangle())
                .onTapGesture {
                    handleContactSelection(contact)
                }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions
    private func loadContacts() async {
        let store = CNContactStore()

        do {
            let status = CNContactStore.authorizationStatus(for: .contacts)

            if status == .notDetermined {
                let granted = try await store.requestAccess(for: .contacts)
                if !granted {
                    await MainActor.run {
                        permissionDenied = true
                        isLoading = false
                    }
                    return
                }
            } else if status == .denied || status == .restricted {
                await MainActor.run {
                    permissionDenied = true
                    isLoading = false
                }
                return
            }

            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]

            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            request.sortOrder = .givenName

            var fetchedContacts: [CNContact] = []
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with phone numbers
                if !contact.phoneNumbers.isEmpty {
                    fetchedContacts.append(contact)
                }
            }

            await MainActor.run {
                contacts = fetchedContacts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                permissionDenied = true
                isLoading = false
            }
        }
    }

    private func handleContactSelection(_ contact: CNContact) {
        if contact.phoneNumbers.count == 1 {
            // Single phone number - select directly
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                selectBuddy(contact: contact, phoneNumber: phone)
            }
        } else {
            // Multiple phone numbers - show picker
            selectedContact = contact
        }
    }

    private func selectBuddy(contact: CNContact, phoneNumber: String) {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let initials = String(contact.givenName.prefix(1)) + String(contact.familyName.prefix(1))

        let buddy = SelectedWorkoutBuddy(
            id: contact.identifier,
            name: name.isEmpty ? "Contact" : name,
            phoneNumber: phoneNumber,
            initials: initials.isEmpty ? "?" : initials.uppercased()
        )

        onSelect(buddy)
        dismiss()
    }
}

// MARK: - Buddy Contact Row
private struct BuddyContactRow: View {
    let contact: CNContact

    private var name: String {
        let full = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? "No Name" : full
    }

    private var initials: String {
        let first = String(contact.givenName.prefix(1))
        let last = String(contact.familyName.prefix(1))
        return (first + last).uppercased()
    }

    private var phoneCount: Int {
        contact.phoneNumbers.count
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 46, height: 46)

                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)

                if phoneCount > 1 {
                    Text("\(phoneCount) phone numbers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let phone = contact.phoneNumbers.first?.value.stringValue {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Phone Number Picker Sheet
private struct PhoneNumberPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let contact: CNContact
    let onSelect: (String) -> Void

    private var name: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            List(contact.phoneNumbers, id: \.identifier) { phoneNumber in
                Button {
                    onSelect(phoneNumber.value.stringValue)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phoneNumber.value.stringValue)
                                .font(.body)
                                .foregroundStyle(.primary)

                            if let label = phoneNumber.label {
                                Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "message.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .navigationTitle("Select Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Contact Wrapper for Sheet
private struct ContactWrapper: Identifiable {
    let contact: CNContact
    var id: String { contact.identifier }
}

#Preview {
    WorkoutBuddyPickerView { buddy in
        print("Selected: \(buddy.name) - \(buddy.phoneNumber)")
    }
}
