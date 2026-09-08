# Fila única de configuración general (ver migración para el porqué de
# columnas explícitas en vez de un key/value genérico).
class AppSetting < ApplicationRecord
  validates :premium_purchase_threshold, presence: true, numericality: { greater_than: 0 }

  # Todo el sistema lee/escribe la configuración a través de esto — nunca
  # `AppSetting.find`/`.new` directamente, para no arriesgarse a tener dos filas.
  def self.current
    first_or_create!
  end
end
