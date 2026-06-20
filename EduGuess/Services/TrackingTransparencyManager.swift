import Foundation
import AppTrackingTransparency
import AdSupport

/// Gestiona la solicitud de permiso de transparencia de rastreo (ATT) requerida por Apple.
enum TrackingTransparencyManager {
    /// Solicita el permiso de rastreo si no se ha determinado aún.
    /// Llama a esto después de que el usuario haya visto la pantalla principal,
    /// nunca en `applicationDidFinishLaunching`.
    static func requestTrackingAuthorization() {
        guard #available(iOS 14, *) else { return }

        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else { return }

        // Retraso leve para no interrumpir el lanzamiento de la app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                // El resultado se maneja automáticamente por el sistema.
                // Si el usuario niega, los identificadores de publicidad devuelven ceros.
            }
        }
    }

    /// Devuelve el estado actual del permiso de rastreo.
    @available(iOS 14, *)
    static var authorizationStatus: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }
}
