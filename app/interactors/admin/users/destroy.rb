module Admin
  module Users
    # Borrado real (no soft-delete, a diferencia de Admin::Products::Destroy):
    # un usuario sin historial (compras, carritos, seguimiento...) se borra
    # sin problema. Si tiene historial, la FK de la base de datos rechaza el
    # borrado — lo capturamos y devolvemos un error entendible en vez de un
    # 500, en vez de intentar armar a mano la lista de qué lo referencia.
    class Destroy
      attr_reader :error

      def self.call(id:)
        new(id: id).call
      end

      def initialize(id:)
        @id = id
        @error = nil
      end

      def call
        user = User.find_by(id: @id)
        unless user
          @error = "User not found"
          return self
        end

        user.destroy!
        self
      rescue ActiveRecord::InvalidForeignKey
        @error = "No se puede borrar: el usuario tiene compras, pedidos u otro historial asociado"
        self
      rescue StandardError => e
        @error = "Error deleting user: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end
