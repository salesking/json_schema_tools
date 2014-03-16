# by http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
class Object # http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html
  def define_class_method( name, &blk)
    (class << self; self; end).instance_eval { define_method name, &blk }
  end
end