require 'google/cloud/firestore'

class Refrigerator
  def initialize(user_id:)
    @refrigerator = Google::Cloud::Firestore.new(project_id: ENV.fetch('GOOGLE_PROJECT_ID')).col(user_id)
  end

  # 材料を冷蔵庫に追加する
  def add_materials(materials)
    materials.each do |material|
      @refrigerator.doc(material).set(name: material)
    end
  end

  # 材料を冷蔵庫から削除する
  def delete_materials(materials)
    materials.each do |material|
      @refrigerator.doc(material).delete
    end
  end

  # 冷蔵庫にある材料を全て返す
  def all_materials
    @refrigerator.get.map { |mat| mat.data[:name] }
  end

  # 指定した食材名のうち, 冷蔵庫に存在しないものを返す
  def not_exists_materials(materials)
    materials.select do |material|
      @refrigerator.where('name', '=', material).get.map { |mat| mat.data[:name] }.empty?
    end
  end
end
