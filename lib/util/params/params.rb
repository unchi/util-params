module Util
  module Params

    # コンストラクタ
    def initialize
      # エラーフラグ
      @is_error = false
      # エラーリスト
      @errors = []
    end
  
    # パラメーター取得
    # param[in] name
    # param[in] default
    # param[in] isRequire
    # param[in] params (min_length, max_length, reg)
    def get_param_str name, default = nil, is_require = false, params = {}
  
      val = get_param_val name, default, is_require
  
      return nil if val.nil?
      v = val.to_s
  
      if params.key? :enum
        for e in params[:enum]
          return v if e === v
        end
        push_error "#{name.to_s} == unknone val [#{v.to_s}]"
      end
  
      if params.key?(:min_length) && (v.length < params[:min_length])
        push_error "#{name.to_s} len [#{v.to_s}] < #{params[:min_length].to_s}"
      end
  
      if params.key?(:max_length) && (v.length > params[:max_length])
        push_error "#{name.to_s} len [#{v.to_s}] > #{params[:max_length].to_s}"
      end
  
      if params.key?(:reg) && !(/#{params[:reg]}/ =~ val)
        push_error "#{name.to_s} unmatch /#{params[:reg].to_s}/ =~ [#{v.to_s}]"
      end
  
      v
    end
    #
    def get_param_strs name, default = [], is_require = false
      vals = get_param_val name, default, is_require
  
      return nil if vals.nil?
  
      vals
    end

    # パラメーター取得
    def get_param_int name, default = nil, is_require = false, params = {}
  
      val = get_param_val name, default, is_require
  
      return nil if val.nil?
      return val if val.kind_of? Integer
  
      if /[^\d]/ =~ val
        push_error "#{name.to_s} type [#{val.to_s}] != integer"
      end
  
      v = val.to_i
  
      if params.key? :enum
        for e in params[:enum]
          logger.debug e
          return v if e === v
        end
        push_error "#{name.to_s} == unknone val [#{v.to_s}]"
      end
  
      if params.key?(:min) && (v.length < params[:min])
        push_error "#{name.to_s} val [#{v.to_s}] < #{params[:min].to_s}"
      end
  
      if params.key?(:max) && (v.length > params[:max])
        push_error "#{name.to_s} val [#{v.to_s}] > #{params[:max].to_s}"
      end
      v
    end

    def get_param_ints name, default = [], is_require = false
      vals = get_param_val name, default, is_require
      return nil if vals.nil?
  
      rs = []
  
      vals.each do |v|
  
        if params.key? :enum
          for e in params[:enum]
            next rs << v.to_i if e === v
          end
          push_error "#{name.to_s} == unknone val [#{v.to_s}]"
        end
  
        if params.key?(:min) && (v.length < params[:min])
          push_error "#{name.to_s} val [#{v.to_s}] < #{params[:min].to_s}"
        end
  
        if params.key?(:max) && (v.length > params[:max])
          push_error "#{name.to_s} val [#{v.to_s}] > #{params[:max].to_s}"
        end
  
        rs << v.to_i
      end
  
      rs
    end
  
    def get_param_objects name, default = [], is_require = false
      vals = get_param_val name, default, is_require
      vals.map do |v|
        v.permit!.to_h.deep_symbolize_keys
      end
    end
  
    def get_param_object name, default = {}, is_require = false
      val = get_param_val name, default, is_require
      val.permit!.to_h.deep_symbolize_keys
    end
  
    #
    def get_param_bool name, default = nil, is_require = false
      val = get_param_val name, default, is_require
      return false if val.kind_of? FalseClass
      return true if val.kind_of? TrueClass
      return nil if val.blank?
      return false if val == 'false'
      return true if val == 'true'
      val.to_i > 0
    end
  
    # ファイル受け取り
    def get_file name, is_require = false
  
      f = params[name]
  
      if is_require
  
        if f.nil?
          push_error "#{name.to_s} == nil"
          return nil
        end
        if f.size.blank?
          push_error "#{name.to_s} == nil"
          return nil
        end
      end
  
      return nil if f.nil?
      return nil if f.size.blank?
  
      f
    end
    #
    def has_param? name
      params.include? name
    end
    # エラーがあるか
    def has_param_error?
      @is_error
    end
    # エラーメッセージ入りスト
    def get_error
      @errors.join ', '
    end
  
  protected
  
    # エラー追加
    def push_error message
      @is_error |= true
      @errors.push message
    end
  
    # パラメーター取得
    def get_param_val name, default, is_require
      unless params.include? name
        push_error "#{name.to_s} == nil" if is_require
        return default
      end
      params[name]
    end

  end

end
