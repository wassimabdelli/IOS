import SwiftUI
import UIKit

struct EditMaillotView: View {
    var playerId: String
    var academyId: String
    @State private var info: APIService.JoueurMaillotInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedNumber: Int = 9
    private let numbers = Array(1...99)
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 6) {
                Text("Edit Maillot")
                    .font(.title2)
                    .foregroundColor(.green)
                ZStack {
                    if let uiImage = UIImage(named: "EditNumber") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 360)
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 360)
                            .overlay(Text("Ajouter EditNumber.png dans Assets").foregroundColor(.gray))
                            .cornerRadius(12)
                    }
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        // Nom + prénom en haut du dos
                        Text("\(info?.prenom ?? "-") \(info?.nom ?? "-")")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .shadow(color: Color.white.opacity(0.9), radius: 2, x: 0, y: 0)
                            .position(x: w/2, y: h * 0.32)
                        // Numéro légèrement plus haut sur le dos
                        Text(info?.numero != nil ? String(info!.numero!) : "-")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.red)
                            .shadow(color: Color.white.opacity(0.9), radius: 2, x: 0, y: 0)
                            .position(x: w/2, y: h * 0.50)
                    }
                    .allowsHitTesting(false)
                }
                if isLoading { ProgressView() }
                Picker("Numéro", selection: $selectedNumber) {
                    ForEach(numbers, id: \.self) { n in
                        Text(String(n))
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                Button(action: assignTapped) {
                    Text((info?.numero != nil) ? "Changer le numéro" : "Attribuer le numéro")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .disabled(isLoading)
                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red).font(.caption)
                }
                Spacer()
            }
            .padding()
        }
        .onAppear(perform: loadInfo)
    }
    private func loadInfo() {
        isLoading = true
        errorMessage = nil
        APIService.getJoueurMaillot(idJoueur: playerId, idAcademie: academyId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let data):
                    info = data
                    selectedNumber = data.numero ?? selectedNumber
                case .failure(let error):
                    errorMessage = (error as? APIError)?.message ?? error.localizedDescription
                }
            }
        }
    }
    private func assignTapped() {
        isLoading = true
        errorMessage = nil
        if info?.numero != nil {
            APIService.updateMaillot(idJoueur: playerId, idAcademie: academyId, numero: selectedNumber) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        info = APIService.JoueurMaillotInfo(nom: info?.nom ?? "", prenom: info?.prenom ?? "", email: info?.email ?? "", numero: selectedNumber)
                    case .failure(let error):
                        errorMessage = (error as? APIError)?.message ?? error.localizedDescription
                    }
                }
            }
        } else {
            APIService.assignMaillot(idJoueur: playerId, idAcademie: academyId, numero: selectedNumber) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        info = APIService.JoueurMaillotInfo(nom: info?.nom ?? "", prenom: info?.prenom ?? "", email: info?.email ?? "", numero: selectedNumber)
                    case .failure(let error):
                        errorMessage = (error as? APIError)?.message ?? error.localizedDescription
                    }
                }
            }
        }
    }
}
