require "google/cloud/firestore"

# 文字分割
def strsplit(str)
    #.,;:/、。と全角半角スペースに対応
    splited = str.split(/\.| |　|,|;|:|\/|、|。/)
    res = []
    #複数個の除去対象がある場合用("A,,B"->["A","","B"]->["A","B"])
    splited.each{|f| res << f if f!=""}
    return res
end

# 冷蔵庫にしまう
def add_to_refri(shopping_bag, refri_col)
    grocery = strsplit(shopping_bag)

    grocery.each{|food| refri_col.doc(food).set(name:food)}
end

# 冷蔵庫から消す
def erase_from_refri(erase_list, refri_col)
    grocery = strsplit(erase_list)

    grocery.each{|food| refri_col.where("name","=",food).delete()}
end

# 冷蔵庫の中身全部抜く
def get_all_grocery(refri_col)
    res = []
    refri_col.get do |food|
        res << food.document_id
    end
    return res
end

# 候補リストを作成する
def make_groc_list(refri_list, num)
    amount = refri_list.size
    res = []
    while true
        idx = rand(0..amount)
        if amount>=2 then
            res << refri_list[idx]
            num -= 1
            if !num break
        else
            res << refri_list[idx]
            break
        end
    end
    return res
end

# 冷蔵庫から取り出す
def get_from_refri(input_list, refri_col)
    grocery = strsplit(input_list)
    res = []

    refri_list = get_all_grocery(refri_col)
    n = refri_list.size
    if n then
        if grocery.size then #食材を指定している場合
            snapshot = refri_col.get.where("name","=",grocery[0])
            if snapshot.exists? then
                res << 1 #食材が見つかったとき(この数字はArray.delete(Array.first)で消去する)
                res << grocery[0]
                res << make_groc_list(refri_list,1)
            else
                res << 0 #見つからなかったとき
                res << make_groc_list(refri_list,2)
            end
        else #指定していないとき
            res << make_groc_list(refri_list,2)
        end
    else
        res << -1 #冷蔵庫に何もなかった時
    end

    return res
end

refri_col = firestore.col "refrigerator"
shopping_bag = "たまご ,    　にんじん トマト,りんご:玉ねぎ;小麦粉/米、もち。白玉" #例文