//
//  EditProfileView.swift
//  IosDam
//
//  Modern Edit Profile screen with photo upload to Supabase

import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var user: UserModel?
    
    // Form fields
    @State private var prenom: String = ""
    @State private var nom: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var tel: String = ""
    @State private var profileImage: UIImage?
    @State private var profileImageURL: String = ""
    
    // UI State
    @State private var showImagePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isUploadingImage = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Photo Section
                        profilePhotoSection
                        
                        // Form Section
                        formSection
                        
                        // Save Button
                        saveButton
                        
                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUser()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
        .onChange(of: profileImage) { newImage in
            if newImage != nil {
                uploadProfileImage()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage.contains("succès") ? "Succès" : "Erreur"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("succès") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .overlay(
            Group {
                if isLoading || isUploadingImage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text(isUploadingImage ? "Upload de la photo..." : "Enregistrement...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(16)
                    }
                }
            }
        )
    }
    
    // MARK: - Custom Header
    
    private var customHeader: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Modifier le profil")
                .font(.system(size: 20, weight: .bold))
            
            Spacer()
            
            // Placeholder for alignment
            Image(systemName: "chevron.left")
                .font(.system(size: 20))
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Profile Photo Section
    
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Photo Circle
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if !profileImageURL.isEmpty {
                    AsyncProfileImage(urlString: profileImageURL, size: 120)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
                
                // Edit Button Overlay
                if isUploadingImage {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 120, height: 120)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
            .overlay(
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
                .offset(x: 40, y: 40),
                alignment: .bottomTrailing
            )
            
            Text("Appuyez pour changer la photo")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Personal Info Card
            VStack(alignment: .leading, spacing: 4) {
                Text("Informations personnelles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                VStack(spacing: 1) {
                    FormFieldRow(icon: "person.fill", title: "Prénom", text: $prenom, iconColor: .blue)
                    Divider().padding(.leading, 52)
                    FormFieldRow(icon: "person.fill", title: "Nom", text: $nom, iconColor: .blue)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            
            // Contact Info Card
            VStack(alignment: .leading, spacing: 4) {
                Text("Contact")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                VStack(spacing: 1) {
                    FormFieldRow(icon: "envelope.fill", title: "Email", text: $email, iconColor: .green, keyboardType: .emailAddress)
                    Divider().padding(.leading, 52)
                    FormFieldRow(icon: "phone.fill", title: "Téléphone", text: $tel, iconColor: .green, keyboardType: .phonePad)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            
            // Birthday Card
            VStack(alignment: .leading, spacing: 4) {
                Text("Date de naissance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                FormFieldRow(icon: "calendar", title: "Date", text: $age, iconColor: .orange, keyboardType: .default)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Enregistrer les modifications")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || isUploadingImage)
        .opacity(isLoading || isUploadingImage ? 0.6 : 1.0)
    }
    
    // MARK: - Functions
    
    func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(UserModel.self, from: userData) {
            user = decodedUser
            prenom = decodedUser.prenom
            nom = decodedUser.nom
            email = decodedUser.email
            age = decodedUser.age
            tel = String(decodedUser.tel)
            profileImageURL = decodedUser.picture ?? ""
        }
    }
    
    func uploadProfileImage() {
        guard let image = profileImage, let userId = user?._id else { return }
        
        isUploadingImage = true
        
        SupabaseService.uploadImage(image: image, userId: userId) { result in
            DispatchQueue.main.async {
                isUploadingImage = false
                
                switch result {
                case .success(let imageURL):
                    self.profileImageURL = imageURL
                    print("✅ Image uploaded: \(imageURL)")
                    
                case .failure(let error):
                    alertMessage = "Erreur lors de l'upload de l'image: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    func saveProfile() {
        guard let userId = user?._id else { return }
        
        // Validate fields
        guard !prenom.isEmpty, !nom.isEmpty, !email.isEmpty else {
            alertMessage = "Veuillez remplir tous les champs obligatoires"
            showAlert = true
            return
        }
        
        guard let telInt = Int(tel) else {
            alertMessage = "Numéro de téléphone invalide"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Prepare update data
        var updateData: [String: Any] = [
            "prenom": prenom,
            "nom": nom,
            "email": email,
            "age": age,
            "tel": telInt
        ]
        
        // Add picture URL if available
        if !profileImageURL.isEmpty {
            updateData["picture"] = profileImageURL
        }
        
        APIService.updateUserProfile(updateData: updateData) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    // Update UserDefaults with new data
                    if let updatedUser = response.user {
                        // Backend returned full user, use it
                        if let encoded = try? JSONEncoder().encode(updatedUser) {
                            UserDefaults.standard.set(encoded, forKey: "currentUser")
                            print("✅ UserDefaults mis à jour avec les données du backend")
                        }
                    } else if var currentUser = self.user {
                        // Backend didn't return user, update manually
                        currentUser.prenom = self.prenom
                        currentUser.nom = self.nom
                        currentUser.email = self.email
                        currentUser.age = self.age
                        currentUser.tel = telInt
                        currentUser.picture = self.profileImageURL.isEmpty ? nil : self.profileImageURL
                        
                        if let encoded = try? JSONEncoder().encode(currentUser) {
                            UserDefaults.standard.set(encoded, forKey: "currentUser")
                            print("✅ UserDefaults mis à jour manuellement")
                            print("📸 Photo URL: \(self.profileImageURL)")
                        }
                    }
                    
                    // Force synchronization
                    UserDefaults.standard.synchronize()
                    
                    alertMessage = "Profil mis à jour avec succès !"
                    showAlert = true
                    
                case .failure(let error):
                    alertMessage = "Erreur: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Form Field Row

struct FormFieldRow: View {
    let icon: String
    let title: String
    @Binding var text: String
    let iconColor: Color
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)
            
            // Title & TextField
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                TextField(title, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Async Profile Image

struct AsyncProfileImage: View {
    let urlString: String
    let size: CGFloat
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                    )
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    func loadImage() {
        SupabaseService.loadImage(from: urlString) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Preview

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}

