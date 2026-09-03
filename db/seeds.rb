# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed de niveles de cliente
levels_data = [
  { name: "Cliente", priority: 1 },
  { name: "Cliente VIP", priority: 2 },
  { name: "Distribuidor", priority: 3 },
  { name: "Distrib VIP", priority: 4 },
  { name: "Constructor del Éxito", priority: 5 },
  { name: "Mayorista", priority: 6 }
]

levels_data.each do |level_attrs|
  level = Level.find_or_initialize_by(name: level_attrs[:name])
  level.priority = level_attrs[:priority]
  level.save!
end

puts "✅ Niveles creados exitosamente: #{Level.count} niveles"

# Seed de categorías
categories_data = [
  { name: "Fórmula 1 - Batido Nutricional", position: 1 },
  { name: "Proteína", position: 2 },
  { name: "Herbal Aloe", position: 3 },
  { name: "Bebida Herbal", position: 4 },
  { name: "Deportes y vida activa", position: 5 },
  { name: "Nutrición Específica", position: 6 },
  { name: "Nutrición Externa", position: 7 },
  { name: "Otros", position: 8 }
]

categories_data.each do |category_attrs|
  category = Category.find_or_initialize_by(name: category_attrs[:name])
  category.position = category_attrs[:position]
  category.save!
end

puts "✅ Categorías creadas exitosamente: #{Category.count} categorías"

# Helper para obtener categoría por nombre
def get_category(name)
  Category.find_by(name: name)
end

# Helper para obtener nivel por nombre
def get_level(name)
  Level.find_by(name: name)
end

# Helper para crear o actualizar producto con precios
def create_product_with_prices(product_data)
  # Usar categoría del Excel si está disponible, sino determinar por nombre
  category = if product_data[:categoria]
    get_category(product_data[:categoria])
  else
    determine_category(product_data[:name])
  end
  
  product = Product.find_or_initialize_by(sku: product_data[:sku])
  product.assign_attributes(
    name: product_data[:name],
    description: product_data[:description],
    # Este seed no trae imágenes (vienen del Excel de precios, no de Storage).
    # Nunca pisar una image_url ya subida vía el panel admin con nil.
    image_url: product_data[:image_url].presence || product.image_url,
    pv: product_data[:pv],
    category: category,
    active: true
  )
  product.save!

  # Crear precios para cada nivel
  product_data[:prices].each do |level_name, price|
    level = get_level(level_name)
    next unless level && price

    product_price = ProductPrice.find_or_initialize_by(
      product: product,
      level: level
    )
    product_price.price = price
    product_price.save!
  end

  product
end

# Helper para determinar categoría basada en el nombre del producto
def determine_category(product_name)
  name_lower = product_name.downcase

  # Fórmula 1
  return get_category("Fórmula 1") if name_lower.include?("fórmula 1") || name_lower.include?("formula 1")

  # Proteína
  if name_lower.include?("proteína") || name_lower.include?("proteina") || 
     name_lower.include?("bebida de proteína") || name_lower.include?("crocante de proteína")
    return get_category("Proteína")
  end

  # Deportes y vida activa
  if name_lower.include?("cr7 drive") || name_lower.include?("h24 rebuild") || 
     name_lower.include?("nrg") || name_lower.include?("guarana")
    return get_category("Deportes y vida activa")
  end

  # Nutrición Externa
  if name_lower.include?("herbalife skin") || 
     name_lower.include?("gel refrescante") || name_lower.include?("crema para manos")
    return get_category("Nutrición Externa")
  end

  # Por defecto: Nutrición Específica (para productos de nutrición interna que no encajan en otras categorías)
  # Si no es nutrición externa ni deportes, probablemente es nutrición específica
  unless name_lower.include?("skin") || name_lower.include?("aloe") || 
         name_lower.include?("cr7") || name_lower.include?("nrg")
    return get_category("Nutrición Específica")
  end

  # Fallback
  get_category("Otros")
end

# Seed de productos basado en lista-precios-distribuidor.xlsx
# Mapeo de precios:
# Cliente (priority: 1) -> Precio de lista
# Cliente VIP (priority: 2) -> Promedio entre Cliente y Distribuidor
# Distribuidor (priority: 3) -> Precio Distribuidor
# Distrib VIP (priority: 4) -> Precio Distrib vip
# Constructor del Éxito (priority: 5) -> Precio Constructor del Éxito
# Mayorista (priority: 6) -> Precio Mayorista

products_data = [
  {
    sku: "395K",
    name: "NutriSoup",
    description: "NutriSoup",
    pv: 18.7,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 99445,
      "Cliente VIP" => 96928,
      "Distribuidor" => 94410,
      "Distrib VIP" => 84840,
      "Constructor del Éxito" => 78140,
      "Mayorista" => 70480
    }
  },
  {
    sku: "1522",
    name: "Fórmula 1 - Banana Caramelo",
    description: "Fórmula 1 - Banana Caramelo",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "0884",
    name: "Fórmula 1 - Chocoavellana",
    description: "Fórmula 1 - Chocoavellana",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "0141",
    name: "Fórmula 1 - Vainilla",
    description: "Fórmula 1 - Vainilla",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "0143",
    name: "Fórmula 1 - Fresa",
    description: "Fórmula 1 - Fresa",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "0146",
    name: "Fórmula 1 - Cookies & Cream",
    description: "Fórmula 1 - Cookies & Cream",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "2638",
    name: "Fórmula 1 - Canela y Especias",
    description: "Fórmula 1 - Canela y Especias",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "2774",
    name: "Fórmula 1 - Café Latte",
    description: "Fórmula 1 - Café Latte",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "187K",
    name: "Fórmula 1 - Dulce de Leche cremoso",
    description: "Fórmula 1 - Dulce de Leche cremoso",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "1134",
    name: "Fórmula 1 - Naranja Crema",
    description: "Fórmula 1 - Naranja Crema",
    pv: 25.75,
    categoria: "Fórmula 1 - Batido Nutricional",
    prices: {
      "Cliente" => 137468,
      "Cliente VIP" => 132939,
      "Distribuidor" => 128410,
      "Distrib VIP" => 114340,
      "Constructor del Éxito" => 104490,
      "Mayorista" => 93230
    }
  },
  {
    sku: "1119",
    name: "Barra con Proteína (1 Caja x 14 Barras)",
    description: "Barra con Proteína (1 Caja x 14 Barras)",
    pv: 16.15,
    categoria: "Proteína",
    prices: {
      "Cliente" => 100421,
      "Cliente VIP" => 102096,
      "Distribuidor" => 103770,
      "Distrib VIP" => 97470,
      "Constructor del Éxito" => 93060,
      "Mayorista" => 88030
    }
  },
  {
    sku: "040K",
    name: "Crocante de Proteína",
    description: "Crocante de Proteína",
    pv: 10.7,
    categoria: "Proteína",
    prices: {
      "Cliente" => 54202,
      "Cliente VIP" => 53331,
      "Distribuidor" => 52460,
      "Distrib VIP" => 47640,
      "Constructor del Éxito" => 44260,
      "Mayorista" => 40410
    }
  },
  {
    sku: "093K",
    name: "Beverage Mix",
    description: "Beverage Mix",
    pv: 23.8,
    categoria: "Proteína",
    prices: {
      "Cliente" => 116994,
      "Cliente VIP" => 115517,
      "Distribuidor" => 114040,
      "Distrib VIP" => 103970,
      "Constructor del Éxito" => 96910,
      "Mayorista" => 88850
    }
  },
  {
    sku: "1122",
    name: "Bebida de Proteína en Polvo - PDM",
    description: "Bebida de Proteína en Polvo - PDM",
    pv: 33.1,
    categoria: "Proteína",
    prices: {
      "Cliente" => 172568,
      "Cliente VIP" => 168289,
      "Distribuidor" => 164010,
      "Distrib VIP" => 147470,
      "Constructor del Éxito" => 135890,
      "Mayorista" => 122660
    }
  },
  {
    sku: "1250",
    name: "Bebida de Proteína en Polvo - PDM - sabor Crema de Maní",
    description: "Bebida de Proteína en Polvo - PDM - sabor Crema de Maní",
    pv: 33.1,
    categoria: "Proteína",
    prices: {
      "Cliente" => 172568,
      "Cliente VIP" => 168289,
      "Distribuidor" => 164010,
      "Distrib VIP" => 147470,
      "Constructor del Éxito" => 135890,
      "Mayorista" => 122660
    }
  },
  {
    sku: "0242",
    name: "Fórmula 3 - Alimento Proteínico en Polvo",
    description: "Fórmula 3 - Alimento Proteínico en Polvo",
    pv: 19.3,
    categoria: "Proteína",
    prices: {
      "Cliente" => 102369,
      "Cliente VIP" => 99000,
      "Distribuidor" => 95630,
      "Distrib VIP" => 85150,
      "Constructor del Éxito" => 77810,
      "Mayorista" => 69430
    }
  },
  {
    sku: "2648",
    name: "Fórmula 3 - Alimento Proteínico en Polvo Frutos rojos",
    description: "Fórmula 3 - Alimento Proteínico en Polvo Frutos rojos",
    pv: 19.3,
    categoria: "Proteína",
    prices: {
      "Cliente" => 102369,
      "Cliente VIP" => 99000,
      "Distribuidor" => 95630,
      "Distrib VIP" => 85150,
      "Constructor del Éxito" => 77810,
      "Mayorista" => 69430
    }
  },
  {
    sku: "238K",
    name: "Golden Beverage",
    description: "Golden Beverage",
    pv: 22.85,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 121847,
      "Cliente VIP" => 117834,
      "Distribuidor" => 113820,
      "Distrib VIP" => 101350,
      "Constructor del Éxito" => 92620,
      "Mayorista" => 82640
    }
  },
  {
    sku: "044K",
    name: "Herbal Relax Infusion - Menta 48 g.",
    description: "Herbal Relax Infusion - Menta 48 g.",
    pv: 40.5,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 191092,
      "Cliente VIP" => 184796,
      "Distribuidor" => 178500,
      "Distrib VIP" => 158940,
      "Constructor del Éxito" => 145250,
      "Mayorista" => 129600
    }
  },
  {
    sku: "1638",
    name: "Bebida Herbal - Chai 51 g.",
    description: "Bebida Herbal - Chai 51 g.",
    pv: 21.45,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 105295,
      "Cliente VIP" => 101828,
      "Distribuidor" => 98360,
      "Distrib VIP" => 87580,
      "Constructor del Éxito" => 80040,
      "Mayorista" => 71410
    }
  },
  {
    sku: "0255",
    name: "Bebida Herbal - Limón 51 g.",
    description: "Bebida Herbal - Limón 51 g.",
    pv: 21.45,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 105295,
      "Cliente VIP" => 101828,
      "Distribuidor" => 98360,
      "Distrib VIP" => 87580,
      "Constructor del Éxito" => 80040,
      "Mayorista" => 71410
    }
  },
  {
    sku: "0106",
    name: "Bebida Herbal - Original 102 g.",
    description: "Bebida Herbal - Original 102 g.",
    pv: 37.6,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 179392,
      "Cliente VIP" => 173481,
      "Distribuidor" => 167570,
      "Distrib VIP" => 149210,
      "Constructor del Éxito" => 136360,
      "Mayorista" => 121660
    }
  },
  {
    sku: "0188",
    name: "Bebida Herbal - Limón 102 g.",
    description: "Bebida Herbal - Limón 102 g.",
    pv: 37.6,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 179392,
      "Cliente VIP" => 173481,
      "Distribuidor" => 167570,
      "Distrib VIP" => 149210,
      "Constructor del Éxito" => 136360,
      "Mayorista" => 121660
    }
  },
  {
    sku: "0189",
    name: "Bebida Herbal - Frambuesa 102 g.",
    description: "Bebida Herbal - Frambuesa 102 g.",
    pv: 37.6,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 179392,
      "Cliente VIP" => 173481,
      "Distribuidor" => 167570,
      "Distrib VIP" => 149210,
      "Constructor del Éxito" => 136360,
      "Mayorista" => 121660
    }
  },
  {
    sku: "0190",
    name: "Bebida Herbal - Durazno 102 g.",
    description: "Bebida Herbal - Durazno 102 g.",
    pv: 37.6,
    categoria: "Bebida Herbal",
    prices: {
      "Cliente" => 179392,
      "Cliente VIP" => 173481,
      "Distribuidor" => 167570,
      "Distrib VIP" => 149210,
      "Constructor del Éxito" => 136360,
      "Mayorista" => 121660
    }
  },
  {
    sku: "2631",
    name: "Herbal Aloe Concentrado - Mandarina",
    description: "Herbal Aloe Concentrado - Mandarina",
    pv: 26.85,
    categoria: "Herbal Aloe",
    prices: {
      "Cliente" => 139418,
      "Cliente VIP" => 134824,
      "Distribuidor" => 130230,
      "Distrib VIP" => 115960,
      "Constructor del Éxito" => 105970,
      "Mayorista" => 94550
    }
  },
  {
    sku: "0006",
    name: "Herbal Aloe Concentrado - Sábila",
    description: "Herbal Aloe Concentrado - Sábila",
    pv: 26.85,
    categoria: "Herbal Aloe",
    prices: {
      "Cliente" => 139418,
      "Cliente VIP" => 134824,
      "Distribuidor" => 130230,
      "Distrib VIP" => 115960,
      "Constructor del Éxito" => 105970,
      "Mayorista" => 94550
    }
  },
  {
    sku: "1065",
    name: "Herbal Aloe Concentrado - Mango",
    description: "Herbal Aloe Concentrado - Mango",
    pv: 26.85,
    categoria: "Herbal Aloe",
    prices: {
      "Cliente" => 139418,
      "Cliente VIP" => 134824,
      "Distribuidor" => 130230,
      "Distrib VIP" => 115960,
      "Constructor del Éxito" => 105970,
      "Mayorista" => 94550
    }
  },
  {
    sku: "3987",
    name: "Collagen Drink",
    description: "Collagen Drink",
    pv: 31.2,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 163792,
      "Cliente VIP" => 159151,
      "Distribuidor" => 154510,
      "Distrib VIP" => 138340,
      "Constructor del Éxito" => 127030,
      "Mayorista" => 114100
    }
  },
  {
    sku: "2864",
    name: "Fibra Activa - Manzana",
    description: "Fibra Activa - Manzana",
    pv: 24.65,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 114070,
      "Cliente VIP" => 110315,
      "Distribuidor" => 106560,
      "Distrib VIP" => 94880,
      "Constructor del Éxito" => 86710,
      "Mayorista" => 77360
    }
  },
  {
    sku: "3122",
    name: "Fórmula 2 - Complejo Multivitamínico",
    description: "Fórmula 2 - Complejo Multivitamínico",
    pv: 10.75,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 56547,
      "Cliente VIP" => 54684,
      "Distribuidor" => 52820,
      "Distrib VIP" => 47040,
      "Constructor del Éxito" => 42980,
      "Mayorista" => 38350
    }
  },
  {
    sku: "0065",
    name: "Herbalifeline ® Plus",
    description: "Herbalifeline ® Plus",
    pv: 27.7,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 144293,
      "Cliente VIP" => 139542,
      "Distribuidor" => 134790,
      "Distrib VIP" => 120020,
      "Constructor del Éxito" => 109680,
      "Mayorista" => 97860
    }
  },
  {
    sku: "0020",
    name: "Xtra Cal Advanced",
    description: "Xtra Cal Advanced",
    pv: 11.0,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 57522,
      "Cliente VIP" => 55631,
      "Distribuidor" => 53740,
      "Distrib VIP" => 47850,
      "Constructor del Éxito" => 43730,
      "Mayorista" => 39020
    }
  },
  {
    sku: "0267",
    name: "Beta Heart",
    description: "Beta Heart",
    pv: 29.25,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 155993,
      "Cliente VIP" => 150857,
      "Distribuidor" => 145720,
      "Distrib VIP" => 129750,
      "Constructor del Éxito" => 118570,
      "Mayorista" => 105800
    }
  },
  {
    sku: "1478",
    name: "DRIVE CR7",
    description: "DRIVE CR7",
    pv: 26.75,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 140393,
      "Cliente VIP" => 136882,
      "Distribuidor" => 133370,
      "Distrib VIP" => 119900,
      "Constructor del Éxito" => 110460,
      "Mayorista" => 99680
    }
  },
  {
    sku: "1417",
    name: "H24 Rebuild Strength - Chocolate",
    description: "H24 Rebuild Strength - Chocolate",
    pv: 56.0,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 287612,
      "Cliente VIP" => 279926,
      "Distribuidor" => 272240,
      "Distrib VIP" => 244230,
      "Constructor del Éxito" => 224630,
      "Mayorista" => 202220
    }
  },
  {
    sku: "0102",
    name: "NRG",
    description: "NRG",
    pv: 15.85,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 81897,
      "Cliente VIP" => 79199,
      "Distribuidor" => 76500,
      "Distrib VIP" => 68120,
      "Constructor del Éxito" => 62250,
      "Mayorista" => 55550
    }
  },
  {
    sku: "075K",
    name: "N-R-G Guaraná Tropical",
    description: "N-R-G Guaraná Tropical",
    pv: 15.85,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 81897,
      "Cliente VIP" => 79199,
      "Distribuidor" => 76500,
      "Distrib VIP" => 68120,
      "Constructor del Éxito" => 62250,
      "Mayorista" => 55550
    }
  },
  {
    sku: "204K",
    name: "Kickoff - Bebida Energizante - Sabor Naranja",
    description: "Kickoff - Bebida Energizante - Sabor Naranja",
    pv: 17.15,
    categoria: "Nutrición Específica",
    prices: {
      "Cliente" => 88586,
      "Cliente VIP" => 85668,
      "Distribuidor" => 82750,
      "Distrib VIP" => 73680,
      "Constructor del Éxito" => 67340,
      "Mayorista" => 60080
    }
  },
  {
    sku: "0766",
    name: "Herbalife SKIN - Limpiador Cítrico para la Piel",
    description: "Herbalife SKIN - Limpiador Cítrico para la Piel",
    pv: 18.0,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 83845,
      "Cliente VIP" => 81083,
      "Distribuidor" => 78320,
      "Distrib VIP" => 69740,
      "Constructor del Éxito" => 63730,
      "Mayorista" => 56870
    }
  },
  {
    sku: "0767",
    name: "Herbalife SKIN - Tonificador Energizante de Hierbas",
    description: "Herbalife SKIN - Tonificador Energizante de Hierbas",
    pv: 13.65,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 65322,
      "Cliente VIP" => 63171,
      "Distribuidor" => 61020,
      "Distrib VIP" => 54330,
      "Constructor del Éxito" => 49650,
      "Mayorista" => 44300
    }
  },
  {
    sku: "0768",
    name: "Herbalife SKIN - Sérum Reductor de Líneas",
    description: "Herbalife SKIN - Sérum Reductor de Líneas",
    pv: 40.55,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 194990,
      "Cliente VIP" => 188565,
      "Distribuidor" => 182140,
      "Distrib VIP" => 162180,
      "Constructor del Éxito" => 148210,
      "Mayorista" => 132240
    }
  },
  {
    sku: "0772",
    name: "Herbalife SKIN - Exfoliante Instantáneo con Arándanos",
    description: "Herbalife SKIN - Exfoliante Instantáneo con Arándanos",
    pv: 14.1,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 67271,
      "Cliente VIP" => 65056,
      "Distribuidor" => 62840,
      "Distrib VIP" => 55960,
      "Constructor del Éxito" => 51140,
      "Mayorista" => 45630
    }
  },
  {
    sku: "0773",
    name: "Herbalife SKIN - Mascarilla Purificadora de Arcilla con Menta",
    description: "Herbalife SKIN - Mascarilla Purificadora de Arcilla con Menta",
    pv: 15.25,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 73122,
      "Cliente VIP" => 70716,
      "Distribuidor" => 68310,
      "Distrib VIP" => 60820,
      "Constructor del Éxito" => 55580,
      "Mayorista" => 49590
    }
  },
  {
    sku: "0899",
    name: "Herbalife SKIN - Crema Humectante Protectora de Día de Amplio Espectro FPS 30",
    description: "Herbalife SKIN - Crema Humectante Protectora de Día de Amplio Espectro FPS 30",
    pv: 30.55,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 145268,
      "Cliente VIP" => 140484,
      "Distribuidor" => 135700,
      "Distrib VIP" => 120830,
      "Constructor del Éxito" => 110420,
      "Mayorista" => 98520
    }
  },
  {
    sku: "2562",
    name: "Herbal Aloe - Gel Refrescante Corporal",
    description: "Herbal Aloe - Gel Refrescante Corporal",
    pv: 8.9,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 38025,
      "Cliente VIP" => 36773,
      "Distribuidor" => 35520,
      "Distrib VIP" => 31630,
      "Constructor del Éxito" => 28910,
      "Mayorista" => 25790
    }
  },
  {
    sku: "2563",
    name: "Herbal Aloe - Crema para Manos y Cuerpo",
    description: "Herbal Aloe - Crema para Manos y Cuerpo",
    pv: 8.9,
    categoria: "Nutrición Externa",
    prices: {
      "Cliente" => 38025,
      "Cliente VIP" => 36773,
      "Distribuidor" => 35520,
      "Distrib VIP" => 31630,
      "Constructor del Éxito" => 28910,
      "Mayorista" => 25790
    }
  }
]

# Crear productos con sus precios
products_created = 0
products_data.each do |product_data|
  begin
    create_product_with_prices(product_data)
    products_created += 1
  rescue => e
    puts "⚠️  Error creando producto #{product_data[:sku]}: #{e.message}"
  end
end

puts "✅ Productos creados exitosamente: #{products_created} de #{products_data.count} productos"
puts "✅ Total de productos en BD: #{Product.count}"
puts "✅ Total de precios en BD: #{ProductPrice.count}"

# ✅ Todos los productos y precios han sido integrados desde lista-precios-distribuidor.xlsx

# Seed del módulo Coach Virtual — Conexión Cuerpo-Emoción
# Ver docs/requirements/coach-cuerpo-emocion-sdd.md (repo qvital-frontend) §4, §10 (Anexo A)
coach_profile = VirtualCoachProfile.find_or_initialize_by(display_name: "Dra. Camila")
coach_profile.gender = :femenino
coach_profile.specialty_description = "Conexión Cuerpo-Emoción"
coach_profile.tone_profile = {
  "rasgos" => %w[cercana calmada sin_juicio nunca_alarmista]
}
coach_profile.active = true
coach_profile.save!

puts "✅ Coach Virtual creada: #{coach_profile.display_name}"

body_regions_data = [
  { name: "Garganta", body_system: :cabeza_cuello, display_order: 1 },
  { name: "Estómago / sistema digestivo", body_system: :digestivo, display_order: 1 }
]

body_regions_data.each do |attrs|
  region = BodyRegion.find_or_initialize_by(name: attrs[:name])
  region.body_system = attrs[:body_system]
  region.display_order = attrs[:display_order]
  region.active = true
  region.save!
end

puts "✅ Zonas del cuerpo creadas: #{BodyRegion.count}"

# Fichas iniciales (Anexo A del SDD) — redactadas por QVITAL, no copiadas de
# ninguna fuente externa. Publicadas para poder probar el flujo end-to-end en
# desarrollo; en producción deben quedar en `borrador` hasta revisión editorial.
insights_data = [
  {
    body_region_name: "Garganta",
    symptom_pattern: "Molestia, opresión, carraspera o nudo frecuente en la garganta, sin causa clínica identificada.",
    emotional_theme: "Dificultad para expresar lo que se piensa o se siente",
    narrative_explanation: "La garganta funciona como el canal entre el pensamiento y la acción: por ahí pasa lo " \
      "que decidimos decir (o callar). Cuando algo importante se queda sin expresar — una palabra que no se dijo, " \
      "un límite que no se puso, una emoción que se \"tragó\" para evitar un conflicto — el cuerpo puede traducir " \
      "esa tensión acumulada en una sensación física en esa zona. No se trata de que \"algo está mal\" en la " \
      "garganta, sino de una posible señal de que hay algo pendiente por decir.",
    reflective_questions: [
      "¿Hay algo que llevas tiempo queriendo decir y no te has permitido expresar?",
      "¿En qué situación reciente sentiste que te 'tragaste' tus palabras?",
      "¿A quién le temes decirle lo que realmente piensas, y qué es exactamente lo que temes que pase?"
    ],
    integration_guidance: "Escribir (sin enviar) la conversación que no has tenido, como ejercicio de descarga. " \
      "Practicar decir una frase pequeña y honesta en voz alta antes de una conversación difícil. Si la molestia " \
      "física persiste más de unos días, consultar con un profesional de salud.",
    severity_flag: :informativo,
    tags: %w[garganta expresion comunicacion],
    status: :publicado,
    content_curation_notes: "Redactado por el equipo QVITAL a partir del marco general de biodescodificación " \
      "revisado en Top Doctors Colombia (ver SDD §1, fuente 2). No es copia ni traducción de ninguna fuente."
  },
  {
    body_region_name: "Estómago / sistema digestivo",
    symptom_pattern: "Molestias digestivas recurrentes (pesadez, acidez, dificultad para digerir) sin causa " \
      "clínica clara.",
    emotional_theme: "Dificultad para 'asimilar' o aceptar una situación, cambio o experiencia reciente",
    narrative_explanation: "Así como el estómago procesa lo que comemos, solemos usar ese mismo lenguaje para " \
      "hablar de experiencias difíciles de aceptar: \"no lo puedo digerir\", \"me cayó pesado\". Cuando hay un " \
      "cambio, una noticia o una situación que cuesta aceptar o procesar emocionalmente, el cuerpo a veces refleja " \
      "esa dificultad de \"asimilación\" en el sistema digestivo. Es una invitación a mirar qué se está intentando " \
      "procesar a nivel emocional, no una explicación única ni definitiva del síntoma.",
    reflective_questions: [
      "¿Qué situación reciente te ha costado aceptar o 'digerir'?",
      "¿Hay un cambio en tu vida que sientes que no has procesado del todo?",
      "¿En qué momento del día notas más la molestia, y qué estabas pensando justo antes?"
    ],
    integration_guidance: "Journaling breve al final del día nombrando una cosa que \"cuesta digerir\". Pausa " \
      "consciente antes de comer (respirar, bajar el ritmo) como práctica de \"recibir\" en vez de \"tragar " \
      "rápido\". Si la molestia física persiste, consultar con un profesional de salud.",
    severity_flag: :informativo,
    tags: %w[digestivo estomago asimilacion cambio],
    status: :publicado,
    content_curation_notes: "Redactado por el equipo QVITAL a partir del marco general de biodescodificación " \
      "revisado en Top Doctors Colombia (ver SDD §1, fuente 2). No es copia ni traducción de ninguna fuente."
  }
]

insights_data.each do |attrs|
  region = BodyRegion.find_by!(name: attrs[:body_region_name])
  insight = BodyEmotionInsight.find_or_initialize_by(body_region: region, symptom_pattern: attrs[:symptom_pattern])
  insight.assign_attributes(attrs.except(:body_region_name, :symptom_pattern))
  insight.save!
end

puts "✅ Fichas Cuerpo-Emoción creadas: #{BodyEmotionInsight.count}"

# Seed de objetivos de salud (Fase 3 — ver docs/requirements/fase3-personalizacion-objetivos-salud.md §2.1)
# Iconos: nombres de lucide-react, usados directamente por el frontend.
health_goals_data = [
  { key: "bajar_peso", name: "Bajar de peso", icon: "TrendingDown", color: "#3d7ea3", position: 1,
    description: "Productos y recetas pensados para perder peso de forma saludable." },
  { key: "subir_peso", name: "Subir de peso", icon: "TrendingUp", color: "#6da8cb", position: 2,
    description: "Productos y recetas para ganar peso de forma saludable." },
  { key: "mantener_peso", name: "Mantener mi peso", icon: "Scale", color: "#43a047", position: 3,
    description: "Productos y recetas para mantener tu peso actual." },
  { key: "nutrirse_bien", name: "Nutrirme bien", icon: "Apple", color: "#cc8079", position: 4,
    description: "Nutrición balanceada para el día a día." },
  { key: "mas_energia", name: "Aumentar mi energía", icon: "Zap", color: "#f59e0b", position: 5,
    description: "Productos pensados para más energía y menos cansancio." },
  { key: "salud_cardiovascular", name: "Cuidar mi corazón", icon: "Heart", color: "#dc2626", position: 6,
    description: "Productos orientados a la salud cardiovascular." },
  { key: "mejorar_digestion", name: "Mejorar mi digestión", icon: "Activity", color: "#9e4c45", position: 7,
    description: "Productos y recetas para una mejor digestión." },
  { key: "snacks_sanos", name: "Snacks sanos", icon: "Sandwich", color: "#bd645c", position: 8,
    description: "Opciones ligeras y saludables para picar entre comidas." },
  { key: "comprar_por_mi_cuenta", name: "Comprar por mi cuenta", icon: "ShoppingBag", color: "#475569", position: 9,
    description: "Omite el filtro por objetivo y muestra todo el catálogo." }
]

health_goals_data.each do |attrs|
  goal = HealthGoal.find_or_initialize_by(key: attrs[:key])
  goal.assign_attributes(attrs.except(:key))
  goal.save!
end

puts "✅ Objetivos de salud creados: #{HealthGoal.count}"

# Seed de recetas (Fase 3.5 — fuente de verdad: docs/knowledge/recetas-mi-nutricion-favorita-tomo-*.md)
#
# Los YAML en db/seed_data/recipes/*.yml son una extracción mecánica de esos
# markdown (mismo texto, mismos SKUs, misma información nutricional). Si el
# markdown cambia, hay que regenerar a mano el YAML correspondiente — no son
# una fuente independiente.
require "net/http"

# Sube la imagen local de una receta (extraída de los PDFs "Mi Nutrición
# Favorita" — ver docs/requirements/recipe-images-req.md) al bucket `recipes`
# de Supabase Storage y devuelve [image_url, image_path]. Mismo mecanismo que
# el upload del panel admin (lib/services/recipeImages.ts en el frontend),
# pero corrido server-side con el service role key porque acá el origen es un
# archivo local, no un <input type="file"> de un navegador.
#
# No rompe el seed si no hay credenciales de Supabase configuradas o si el
# archivo local no existe — solo lo reporta y sigue.
def upload_recipe_image(slug:, local_path:)
  return [nil, nil] if local_path.blank?

  if ENV["SUPABASE_URL"].blank? || ENV["SUPABASE_SERVICE_ROLE_KEY"].blank?
    puts "⚠️  SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY no configurados — se omite la subida de imagen de #{slug}"
    return [nil, nil]
  end

  unless File.exist?(local_path)
    puts "⚠️  Imagen local no encontrada para #{slug}: #{local_path}"
    return [nil, nil]
  end

  ext = File.extname(local_path).delete_prefix(".").presence || "jpg"
  content_type = { "jpg" => "image/jpeg", "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp" }
                 .fetch(ext, "application/octet-stream")
  object_path = "#{slug}.#{ext}"

  uri = URI.join(ENV["SUPABASE_URL"], "/storage/v1/object/recipes/#{object_path}")
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{ENV['SUPABASE_SERVICE_ROLE_KEY']}"
  request["apikey"] = ENV["SUPABASE_SERVICE_ROLE_KEY"]
  request["Content-Type"] = content_type
  request["x-upsert"] = "true"
  request.body = File.binread(local_path)

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
  unless response.is_a?(Net::HTTPSuccess)
    puts "⚠️  Error subiendo imagen de #{slug} a Supabase Storage: #{response.code} #{response.body}"
    return [nil, nil]
  end

  image_url = URI.join(ENV["SUPABASE_URL"], "/storage/v1/object/public/recipes/#{object_path}").to_s
  [image_url, object_path]
end

recipe_seed_files = Dir[Rails.root.join("db/seed_data/recipes/*.yml")].sort
recipes_data = recipe_seed_files.flat_map { |file| YAML.load_file(file).map(&:deep_symbolize_keys) }

duplicate_recipe_slugs = recipes_data.group_by { |r| r[:slug] }.select { |_, v| v.size > 1 }.keys
raise "Slugs duplicados en seed_data de recetas: #{duplicate_recipe_slugs.join(', ')}" if duplicate_recipe_slugs.any?

recipes_created = 0
recipes_updated = 0
recipe_ingredient_warnings = []

recipes_data.each do |data|
  recipe = Recipe.find_or_initialize_by(slug: data[:slug])
  is_new_recipe = recipe.new_record?

  recipe.assign_attributes(
    title: data[:title],
    description: data[:description],
    servings: data[:servings],
    difficulty: data[:difficulty],
    recipe_type: data[:recipe_type],
    calories: data[:calories],
    protein_g: data[:protein_g],
    carbs_g: data[:carbs_g],
    fat_g: data[:fat_g],
    fiber_g: data[:fiber_g],
    tips: data[:tips],
    source: data[:source],
    instructions: data[:instructions],
    active: true
  )
  recipe.save!

  # Sube la imagen local (si el YAML trae `image_local_path` y hay
  # credenciales de Supabase) y la asigna a la receta. Solo pisa image_url/
  # image_path si están vacíos o si ya apuntan a un archivo subido por este
  # mismo seed (nombre "<slug>.<ext>") — nunca sobreescribe una imagen subida
  # a mano desde el panel admin, que usa un nombre aleatorio (uuid).
  if data[:image_local_path].present?
    expected_ext = File.extname(data[:image_local_path]).delete_prefix(".").presence || "jpg"
    expected_image_path = "#{data[:slug]}.#{expected_ext}"

    if recipe.image_path.blank? || recipe.image_path == expected_image_path
      image_url, image_path = upload_recipe_image(slug: data[:slug], local_path: data[:image_local_path])
      recipe.update!(image_url: image_url, image_path: image_path) if image_url
    end
  end

  # Reemplaza todos los ingredientes en vez de diffear por id — mismo
  # criterio que Admin::Recipes::Update, y hace el seed naturalmente
  # idempotente ante cambios en el YAML de origen.
  recipe.recipe_ingredients.destroy_all
  Array(data[:ingredients]).each_with_index do |ingredient, index|
    product = ingredient[:sku].present? ? Product.find_by(sku: ingredient[:sku]) : nil
    if ingredient[:sku].present? && product.nil?
      recipe_ingredient_warnings << "#{data[:slug]}: SKU #{ingredient[:sku]} (#{ingredient[:name]}) no encontrado en products — se usó nombre genérico"
    end

    recipe.recipe_ingredients.create!(
      product_id: product&.id,
      generic_name: product ? nil : ingredient[:name],
      quantity: ingredient[:quantity],
      is_optional: ingredient[:is_optional] || false,
      position: index
    )
  end

  is_new_recipe ? recipes_created += 1 : recipes_updated += 1
rescue StandardError => e
  raise "Error creando/actualizando la receta \"#{data[:title]}\" (#{data[:slug]}): #{e.class}: #{e.message}"
end

puts "✅ Recetas creadas: #{recipes_created}, actualizadas: #{recipes_updated} (total #{Recipe.count})"
if recipe_ingredient_warnings.any?
  puts "⚠️  Advertencias de ingredientes de recetas (SKU no encontrado):"
  recipe_ingredient_warnings.each { |w| puts "   - #{w}" }
end
