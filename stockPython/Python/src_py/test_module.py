
def test_function(model_out):
    print model_out.shape
    conv_factor=4
    conv_out_y=160
    conv_out_x=120
    x,y=get_conv_coords(conv_factor,conv_out_y,conv_out_x)
    probs=np.swapaxes(model_out[0,:,:],0,3).reshape(-1)>0.9
    x=x[probs]
    y=y[probs]
    _,y_clust=cluster_points(np.ones(y.shape[0])*200,y , dist_th=5, clust_th=30)
    x_clust,_=cluster_points(x, np.ones(x.shape[0])*200, dist_th=5, clust_th=30)
    nx,ny=x_clust.shape[0],y_clust.shape[0]
    min_x=np.min(x_clust)
    max_x=np.max(x_clust)
    min_y=np.min(y_clust)
    max_y=np.max(y_clust)
    ratio=(max_x - min_x)/(max_y-min_y)
    return min_x,min_y,max_x,max_y
