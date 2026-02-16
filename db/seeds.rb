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
  "Fórmula 1 - Batido Nutricional",
  "Proteína",
  "Herbal Aloe",
  "Bebida Herbal",
  "Deportes y vida activa",
  "Nutrición Específica",
  "Nutrición Externa",
  "Otros"
]

categories_data.each do |category_name|
  Category.find_or_create_by!(name: category_name)
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
    image_url: product_data[:image_url],
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
