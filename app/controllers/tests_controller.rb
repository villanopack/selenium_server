class TestsController < ApplicationController
  before_action :set_test, only: [:show, :edit, :update, :destroy]

  def index
    @tests = Test.order('id DESC').page params[:page]
  end

  def show
  end

  def destroy
    @test.destroy
    respond_to do |format|
      format.html { redirect_to tests_url, notice: 'Test was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_test
      @test = Test.find(params[:id])
    end

    def test_params
      params.require(:test).permit()
    end
end
